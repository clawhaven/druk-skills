# Testing (house rules)

Read this before writing or reviewing tests. For general Python style see `python-style.md`; for Django/DRF/Celery code see `django.md`.

## Testing Principles

- Add or update focused tests when changing behavior, fixing a bug, or locking in an important contract.
- Tests document behavior, not implementation.
- A test method name plus its one-line docstring should tell the complete story being verified.
- Prefer existing repo test utilities over new helpers.
- Use `MODULE = "dotted.module.path"` constants for patch targets.
- Use `setUpTestData` for shared read-only fixtures.
- Use `setUp` for per-test mutable state.
- Call `refresh_from_db()` in `setUp` for shared objects that tests may mutate.
- Use `subTest` for enum-driven exhaustive loops.
- Use `@mock.patch(...)` decorators on test methods, not in `setUp`.
- Use `save(update_fields=...)` in setup mutations.
- Use `with self.assertRaises(...) as context:` when inspecting exception attributes.
- Prefer `assertRaisesMessage` when error text matters.
- Use `mock.ANY` where exact values do not matter.
- Wrap the action and assertions together with `override_settings`.
- Use `assertNumQueries` for query-count regressions.
- Use `with (...):` multi-context-manager syntax rather than nested `with` blocks.
- Patch logger methods with `mock.patch.object(logger, "info")` for log assertions.
- Use local `namedtuple` inside a test method for tabular input/expected pairs.
- Use `# Sanity check` before baseline assertions that establish preconditions.
- Put repetitive assertion logic behind `assert<Domain><Condition>` helpers.
- Use a wrapper like `force_authenticate(user)` when it better expresses test intent than raw client APIs.
- Use `@property` for repeated admin URLs.
- Set an inherited test method to `None` to disable it in a subclass when not applicable.
- Use `@unittest.skip("reason")` at class level to disable suites, always with a reason.

```python
MODULE = "core.apis.external"


class AdminUpdateTests(AdminBaseTestCase):
    def test_update(self):
        """Updates the object when the admin has access."""
        ...

    def test_wrong_room(self):
        """Rejects updates when the object belongs to another room."""
        ...


def test_sanitization(self):
    """Normalizes user-visible filenames."""
    Combination = namedtuple("Combination", "input,expected")
    combinations = [
        Combination(input="cafe", expected="cafe"),
        Combination(input="file  name", expected="file name"),
    ]
    for combination in combinations:
        with self.subTest(f"input={combination.input!r}"):
            self.assertEqual(sanitize(combination.input), combination.expected)
```

## Django Test Patterns

- Implement `run_commit_hooks()` on base test cases when code uses `transaction.on_commit`.
- For request-factory tests, provide `get_request()` helpers that set `request.resolver_match`.
- Use `task.s().set(task_id=task_id).delay()` when a test needs to control Celery task IDs.
- Fake backend classes may use `mock.Mock()` as class-level spies; reset them in `setUp`.
- Form test hierarchies can use `form_class = None`, `get_form_kwargs()`, and `get_form()`.
- System checks are tested end-to-end with `call_command("check")` and `assertRaisesMessage(SystemCheckError, ...)`.
- Use role-based test class hierarchies: neutral base fixtures, role-specific base setup, concrete behavior tests.
- Base test classes should not contain test methods.
- View tests using a request mixin declare `get_view()`, `get_data()`, and `get_kwargs()`.
- Avoid direct `self.client.*` calls in view tests when the repo provides request helpers.
- Use resource-access/security mixins for IDOR and XSS coverage when the repo has them.
- Use `describe_*()` helpers for large expected serializer dictionaries.
- Use machine-readable metadata decorators on test classes when the repo has them.
- Use teardown plus patched side effects and `run_commit_hooks()` when post-commit work is not the test's concern.
- Temporary test skips must include a clear reason or ticket reference. Use neutral ticket examples such as `PROJ-1234`.

```python
def run_commit_hooks(self):
    func = "django.db.backends.base.base.BaseDatabaseWrapper.validate_no_atomic_block"
    for db_name in reversed(self._databases_names()):
        with mock.patch(func, lambda a: False):
            transaction.get_connection(using=db_name).run_and_clear_commit_hooks()


class BaseChunkedUploadFormTestCase(BaseChunkedUploadTestCase):
    form_class = None

    def get_form_kwargs(self):
        return {"bucket_name": self.bucket_name}

    def get_form(self, *, data=None):
        return self.form_class(data=data or {}, **self.get_form_kwargs())
```
