# Django / DRF / Celery (house rules)

Django-specific conventions. Read this before writing or reviewing Django, DRF, or Celery code. For general Python style see `python-style.md`; for tests see `testing.md`.

## Django App Layout

Each Django app separates concerns into dedicated files rather than growing a fat
`models.py`.

| File | Contents |
| --- | --- |
| `models.py` | Model classes only, imports from siblings |
| `query.py` | `QuerySet` subclasses |
| `enums.py` | `TextChoices` / `IntegerChoices` and grouped state tuples |
| `admin.py` | Admin registration |
| `forms.py` | Form classes |
| `views.py` / `viewsets.py` | View logic |
| `signals.py` | Signal definitions |
| `signal_handlers.py` | Signal receivers |
| `tasks.py` | Celery tasks |
| `factories.py` | Test factories |
| `checks.py` | Django system checks registered in `AppConfig.ready()` |

## Django Models

- Member order within a model: fields first, then `class Meta`, then `__str__`, then domain methods (`save`, state transitions, `get_absolute_url`), then classmethods and properties last.
- UUID primary keys use the four-line block in fixed order.
- Timestamp fields set programmatically use `editable=False`.
- Use inline field comments for non-obvious "set when / why" fields.
- Soft-delete is a nullable `deleted_at` `DateTimeField`, not a boolean.
- State-machine transitions use `set_state(state, update_fields=())`.
- `get_active()` classmethods return `.first()`, not `.get()`.
- `__str__` returns one meaningful identifier using f-strings.
- Use `related_name="+"` when the reverse relation is never needed.
- Use `on_delete=models.PROTECT` on one-to-one extension sidecar models.
- Put class-level `re.compile(...)` constants on models when the pattern belongs to that model.
- Every `JSONField` carries `encoder=DjangoJSONEncoder`.
- Use `GinIndex` for `ArrayField` and `JSONField` containment queries; remove `db_index=True` from those fields.
- Use `UniqueConstraint(condition=models.Q(...))` for state-dependent uniqueness.
- Constraint and index names on abstract models use `%(class)s`.

```python
id = models.UUIDField(
    primary_key=True,
    default=uuid.uuid4,
    editable=False,
)


class Release(models.Model):
    task_kwargs = models.JSONField(blank=True, default=dict, encoder=DjangoJSONEncoder)

    class Meta:
        ordering = ("-created_at",)

    def __str__(self):
        return f"Release {self.pk}"

    def set_state(self, state, update_fields=()):
        self.state = state
        self.state_updated_at = timezone.now()
        self.save(update_fields=("state", "state_updated_at") + update_fields)

    @classmethod
    def get_active(cls):
        return cls.objects.filter(is_active=True, expires_at__gt=timezone.now()).first()
```

## Django QuerySets And ORM

- All meaningful `QuerySet` subclasses live in `query.py`.
- Every meaningful domain state slice gets a named queryset method.
- Soft-delete models expose paired `active()` and `deleted()` methods.
- Prefer named queryset filters over raw `.filter()` scattered through call sites.
- Use `Prefetch(..., to_attr="{relation}_{applied_filter}")`.
- Use `.iterator()` on large querysets in service loops.
- Use `.delete()[1].get("app.ModelName", 0)` to extract a specific model's cascade-delete count.
- Use `save(update_fields=(...))` for updates. Avoid bare `.save()` unless creating a new model or local convention requires it.
- Use `transaction.on_commit(lambda: ...)` for post-commit side effects.
- Freeze loop variables in `on_commit` lambdas with default args.
- Use `@transaction.atomic` on methods and `@transaction.atomic()` on standalone task functions.
- Pair `select_for_update(of=("self",))` with `@transaction.atomic`.
- Use `objects.only("pk")` when only identity matters.
- Use `F().asc(nulls_first=True)` for nullable sort columns.
- Use `Subquery`, `OuterRef`, and `annotate` for correlated single-value lookups.
- Use `update_or_create` / `get_or_create` with explicit `defaults={}` when defaults are empty.
- Batch scripts use `BATCH_SIZE`, offset loops, and `DRY_RUN` guards.

```python
class EnvironmentQuerySet(models.QuerySet):
    def active(self):
        return self.filter(deleted_at__isnull=True)

    def deleted(self):
        return self.filter(deleted_at__isnull=False)


transaction.on_commit(
    lambda integration_id=integration.pk: self._post_in_thread(integration_id)
)
```

## Django Enums And Constants

- Put all `TextChoices` / `IntegerChoices` in `enums.py`.
- Each enum value gets a line-above comment explaining business meaning.
- Export logically grouped state tuples at module level alongside the choices class.
- Keep flag or enum entries sorted alphabetically when the repo convention requires it.

```python
class RELEASE_STATES(models.TextChoices):
    # The release has been created but not yet queued
    CREATED = "created"
    # The operation request has been created and is running
    DEPLOYMENT_ONGOING = "deployment-ongoing"
    # The operation finished successfully
    FINISHED = "finished"


ONGOING = (
    RELEASE_STATES.DEPLOYMENT_ONGOING,
)
FINISHED = (
    RELEASE_STATES.FINISHED,
    RELEASE_STATES.FAILED,
)
```

## Django Forms

- Scheduling forms expose `get_environment()` and `get_config()`; schedulers do not touch `cleaned_data` directly.
- `get_config()` starts with `super().get_config()`.
- Optional boolean config keys are written only when explicitly changed.
- `clean()` starts with `data = super().clean()` and returns early if `self._errors`.
- Use `self.add_error("field", "msg")` for field-specific errors when execution can continue.
- Use `field_order` as a class attribute when display order differs from declaration order.
- Non-`ModelForm` forms that create objects expose `save()`.

```python
def clean(self):
    data = super().clean()

    if self._errors:
        return data

    if group.instances.filter(slug=data["slug"]).exists():
        raise forms.ValidationError("Slug already taken.")
    return data
```

## Django Admin

- Use `@admin.register(Model)` decorators, not `admin.site.register()`.
- Use `@admin.display(boolean=True)` for boolean computed columns.
- Use `@admin.action(description="...")` for actions.
- Use `add_form` plus `get_form(obj is None)` to switch between add and change forms.
- Guard `get_inlines()` and `get_readonly_fields()` on `obj is None`.
- Use `editable_fields` plus dynamic `get_readonly_fields()` instead of maintaining full readonly lists.
- Use `list_select_related` for FK/O2O fields used in `list_display`.
- Use `prefetch_related()` in `get_queryset()` for M2M.
- Use `admin.SimpleListFilter` for dynamic filter options.
- Defer expensive imports in admin filters into `lookups()`, not module scope.
- Return `model.objects.none()` on initial unfiltered changelists when a full scan is expensive.
- Use `pprint.pformat(data, indent=4)` for read-only display of decoded dict/list payloads.
- Read-only admin classes define all three permission methods returning `False`.

```python
@admin.register(Environment)
class EnvironmentAdmin(admin.ModelAdmin):
    add_form = EnvironmentAdminAddForm
    editable_fields = ("manifest_branch", "auto_sync_enabled")

    def get_form(self, request, obj=None, **kwargs):
        defaults = {}
        if obj is None:
            defaults["form"] = self.add_form
        defaults.update(kwargs)
        return super().get_form(request, obj, **defaults)
```

## Celery And Tasks

- In `tasks.py`, use `get_task_logger(__name__)`.
- Drain tasks stack `@transaction.atomic()` under the task decorator.
- Use `trail=False` for self-rescheduling drain tasks.
- Reschedule drain tasks with `transaction.on_commit(lambda: task.delay())`.
- Capture object data dicts before deletion so post-deletion logging has data.
- Use `model_path` plus `apps.get_model()` for model-generic tasks.
- Pass `document._meta.label_lower` at the call site and resolve inside the task.
- Use `throws=ExceptionClass` on tasks for expected re-raises to reduce Celery noise.
- `CELERY_BEAT_SCHEDULE` entries are preceded by a `# Frequency at time` comment.

```python
@app.task(bind=True, trail=False)
@transaction.atomic()
def cleanup_deleted_environments(self):
    environment = (
        Environment.objects.select_for_update(skip_locked=True, of=("self",))
        .order_by("deleted_at")
        .deleted()
        .first()
    )
    if environment:
        data = {"id": str(environment.pk), "slug": environment.slug}
        environment.hard_delete()
        self.add_run_context({"deleted": data})
        logger.info("Deleted environment %s with ID %s.", data["slug"], data["id"])
        transaction.on_commit(lambda: cleanup_deleted_environments.delay())
    else:
        logger.info("No environments pending deletion.")
```

## Signals

- Custom signals live in `signals.py`.
- Receivers live in `signal_handlers.py` unless they are tightly model-adjacent.
- `dispatch_uid` matches the handler function name.
- Connect signals in `AppConfig.ready()`.
- Side-effect-only imports in `ready()` carry the repo's lint/IDE suppression comments.
- Use `@wraps(func)` on decorators that wrap signal receivers.

```python
# signals.py
manifest_branch_updated = Signal()

# signal_handlers.py
@receiver(manifest_branch_updated, dispatch_uid="request_sync")
def request_sync(**kwargs):
    ...

# apps.py
def ready(self):
    # pylint: disable=unused-import
    import environments.signal_handlers
```

## Migrations And System Checks

- Data migrations use `apps.get_model()`, never direct model imports.
- Data migrations use `save(update_fields=(...))`.
- Irreversible data migrations use `reverse_code=migrations.RunPython.noop`.
- If a migration is genuinely reversible, implement the full reverse function.
- Use `atomic = False` plus `AddIndexConcurrently` for non-locking index creation.
- Define custom `Func` subclasses locally in migration files for SQL the ORM cannot express.
- Include a missing-migrations test in every Django app when that is the repo convention.
- Django system checks live in `checks.py`.
- Register checks by importing them inside `AppConfig.ready()`.
- System check IDs follow `<app_label>.E<NNN>`.

```python
def set_operation_state(apps, schema_editor):
    Operation = apps.get_model("operations", "Operation")
    for operation in Operation.objects.all():
        operation.state = mapping[operation.state_tmp]
        operation.save(update_fields=("state",))


class Migration(migrations.Migration):
    atomic = False

    operations = [
        AddIndexConcurrently(
            model_name="circuit",
            index=models.Index(fields=["state"], name="idx_state_on_circuit"),
        ),
    ]
```

## Settings

- In library-style packages, use a `conf.py` module as the single accessor layer to Django settings.
- Required settings are bare and fail loudly on startup.
- Optional settings use `getattr(settings, "X", default)` or env helpers with `default=`.
- Application code imports `from . import conf`; avoid direct `settings.X` reads outside settings/accessor modules.
- Tests patch the module object when that is the established local pattern.
- Use `if "test" in sys.argv:` for test-only apps with test models when avoiding a separate test settings file.
- Optional infrastructure integrations are gated by `if env("VAR"):` blocks, using walrus when the value is reused.
- Settings sections may use banner comments when the settings file already follows that style.
- Never call `load_settings()` at module import time. Settings reads happen inside function bodies, not as module-level state.
- The one allowed exception is when a third-party API forces a value at decorator-evaluation time (e.g., a task broker's queue URL or a scheduler's cron string). In that case, read the single required env var directly via `os.environ.get(...)` — do not load the whole settings object.
- Background-task modules follow this pattern: project-wide `broker.py` defines the broker singleton from one env var; per-domain `<subpackage>/tasks.py` imports the broker and defines tasks. Each task body calls `load_settings()` and opens DB sessions per invocation, then commits/rollbacks/closes in a try/finally.

```python
# conf.py
STORAGE_BACKENDS = settings.MANAGED_FILE_STORAGE_BACKENDS
BUFFER_SIZE = getattr(settings, "MANAGED_FILE_DEFAULT_BUFFER_SIZE", 8192)
```

## DRF And Viewsets

- Use the repo's standard response helpers instead of inlining serializer validation and response assembly.
- Query string access goes through validated serializers; avoid raw `request.query_params.get(...)`.
- Put per-app query serializers in `query_params.py` when that pattern exists.
- `SerializerMethodField` delegates to `obj.get_<field>()` when business logic belongs on the model.
- Use `@cached_property` on viewset resource properties that fetch parent objects.
- Serializer `save()` delegates to services via `self.context`; avoid business logic in `create()` / `update()`.
- Use the repo's safe-input serializer mixin on serializers with text fields when XSS validation is required.
- Use the repo's room/resource mixins instead of inline parent-object lookup logic.

```python
class RoomSerializer(serializers.ModelSerializer):
    invitation_documents_count = serializers.SerializerMethodField()

    def get_invitation_documents_count(self, obj):
        return obj.get_invitation_documents_count()


class InvitationDocumentViewSet(BaseViewSet):
    @cached_property
    def meeting(self):
        return get_object_or_404(Meeting, pk=self.kwargs["meeting_pk"])
```

## Throttling, Authorization, And Flags

- Rate-limited endpoints define burst and sustained throttle classes when using DRF user throttles.
- Scope strings follow the repo's `<app>_<resource>_<action>_burst` / `_sustained` pattern.
- Register throttle scopes in settings before shipping the endpoint.
- Use action-based throttle scope mixins for per-action viewset throttles.
- Use helper functions such as `throttle_by_key()` for non-user keys when available.
- Business authorization logic lives in per-app `rules.py` when the repo uses rules predicates.
- Predicates are decorated and registered with `add_rule("can_<verb>_<noun>", fn)`.
- Views and serializers call `test_rule("can_<verb>_<noun>", actor, obj)`.
- Feature flag keys are declared centrally; do not pass raw strings to flag checks.
- Tests use the repo's feature-flag mixin/helpers so flag-gated paths are explicit.

## Management Commands And Middleware

- Multi-operation management commands use the repo's click/djclick group pattern when present.
- Plain `BaseCommand` is for single-operation commands.
- Management command output uses `self.stdout.write` and `self.style.*`; avoid `print()`.
- Progress sections may use `"-" * 60` delimiters when the repo does.
- New middleware uses the callable middleware style with `__init__(self, get_response)` and `__call__(self, request)`.
- Do not subclass `MiddlewareMixin` for new middleware.
