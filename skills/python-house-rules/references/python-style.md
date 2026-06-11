# Python Style (general)

General Python rules from the house style. Read this for any non-trivial Python work, regardless of framework. For Django/DRF/Celery specifics see `django.md`; for tests see `testing.md`.

## PEP 8 Baseline

PEP 8 is the baseline Python style guide. Apply it by default, then layer these
house rules and repo-local conventions on top. If a formatter or linter config
differs from plain PEP 8, follow the repo config.

- Use four spaces for indentation; never use tabs for indentation.
- Keep lines within the repo's configured limit. If none is configured, use 88
  characters for Black-style repos and 79 characters for strict PEP 8 repos.
- Use `snake_case` for functions, methods, variables, modules, and packages.
- Use `PascalCase` for classes and exceptions.
- Use `UPPER_SNAKE_CASE` for constants.
- Put imports at the top of the file, grouped and separated by blank lines.
- Keep whitespace boring: no spaces inside brackets, one space after commas,
  no trailing whitespace, and no extra spaces around keyword/default arguments.
- Use two blank lines between top-level definitions and one blank line between
  methods, unless the repo formatter says otherwise.
- Make public names descriptive. Avoid single-letter names except for tiny local
  scopes, coordinates, and conventional type variables.
- Spell names out; do not truncate or abbreviate words. Use `sandbox` not `sb`,
  `request` not `req`, `manager` not `mgr`, `response` not `resp`. The full word
  costs nothing to read and removes guesswork. Established domain acronyms
  (`url`, `id`, `http`, `db`) and conventional loop indices are fine.
- Use leading underscores for internal helpers and implementation details.
- Do not fight the formatter. If Black, Ruff, isort, or another repo tool would
  rewrite the code, write it in the shape the tool expects.

```python
# Good
class ArchiveRunError(Exception):
    pass


MAX_RETRIES = 3


def schedule_archive_run(*, run_id: str, force: bool = False) -> None:
    ...


# Bad
class archive_run_error(Exception):
    pass


maxRetries = 3


def ScheduleArchiveRun(runId: str, force=False):
    ...
```

## General Python Style

- Prefer clear, typed Python over clever Python.
- Add or preserve type hints on public functions, methods, and structured data.
- Use `X | None` in new code; leave existing `Optional[X]` alone unless touching the signature.
- Do not use `from __future__ import annotations` in code targeting Python 3.10+. Modern union syntax (`X | None`), `list[X]`, `dict[K, V]` evaluate natively. The `__future__` import hides forward-reference bugs (definition-order issues that wouldn't otherwise compile).
- Do not retrofit type hints into very old code unless touching that function.
- Annotate non-obvious local types.
- Prefer `ClassVar` for dataclass class-level constants so they are excluded from `__init__`.
- Use `NoReturn` for functions that always raise.
- Use `Any` on abstract slots where concrete subclasses narrow the type.
- Use type aliases for repeated complex types; do not introduce aliases for one-off annotations.
- Use `TypeVar` / `ParamSpec` only when the type relationship matters to callers.
- Use `Protocol` for structural interfaces when behavior is required but inheritance is not.
- Prefer `NamedTuple` classes with typed fields and `__str__` for simple immutable records.
- Use `@dataclass` for value objects that need `__post_init__`, derived state, or inheritance.
- Avoid mutable default arguments; use `None` sentinels or `field(default_factory=...)`.
- Prefer module namespace imports when the imported module acts as a namespace.
- Prefer `import contextlib` over `from contextlib import suppress`.
- Use context managers for resources with paired setup/teardown.
- Use custom context managers only when they make the call site clearer than `try/finally`.
- Use `functools.wraps` on decorators that wrap callables.
- Prefer bare `return` for guard exits and let void functions fall off the end.
- Never write `return None` when `return` or falling off means the same thing.
- Compare `None` with `is` / `is not`; use `isinstance()` instead of `type(...) == ...`.
- In dict literals, use meaningful field order; put the most identifying field first.
- If a variable assignment is immediately followed by `if`, `for`, or `with`, insert a blank line between them.
- Do not apply that blank-line rule to every assignment.
- Use list comprehensions only for simple one-to-one transformations.
- Use regular loops for side effects or multiple operations per item.
- Avoid nested comprehensions; extract to a loop.
- Use generator expressions when an aggregate can stream values instead of building a list.
- Use generator functions for large or streaming inputs.
- Use `str.partition()` over `str.split()` for a single guaranteed split.
- Use raw string literals for regex patterns, even when the pattern has no backslash.
- Use starred discard (`first, *_ = values`) when only the head is meaningful.
- Use `enumerate()` instead of manually maintaining an index.
- Use `zip(..., strict=True)` when paired iterables are expected to have equal length.
- Use walrus expressions for conditional-then-use, not assignment-only.
- Capture boolean state before mutating an object when the old state matters.
- Use `pathlib.Path` for new filesystem path logic unless the repo already standardizes on `os.path`.
- Script-level constants go before all logic and use `UPPER_SNAKE_CASE`.
- Module-level ordering is constants → functions → classes. Put module-level functions at the top of the file, above class definitions; never bury functions below the classes. Exception: a class needed at module-evaluation time (used as a base class, a decorator, or a default-argument value) must appear before that use.
- Prefer keyword-only service functions when positional calls would be unclear.
- Use `__slots__` only for high-volume non-model objects where memory savings justify the API constraint.
- Avoid string concatenation in loops; use `"".join(...)` or `io.StringIO`.

```python
from typing import NamedTuple


def create_chunked_file(*, name, content_type, bucket_name):
    return ChunkedFile.objects.update_or_create(
        name=name,
        bucket_name=bucket_name,
        defaults={"content_type": content_type},
    )


class ReleaseImageTag(NamedTuple):
    date: str
    time: str
    pr_number: str
    hash: str

    def __str__(self):
        return f"{self.date}T{self.time}.{self.pr_number}.{self.hash}"
```

## Good / Bad Python Examples

Use these examples as calibration points when generating or reviewing code. Each
pair states the concrete failure mode of the Bad version, so the distinction is
never left implicit.

Prefer domain names over clever abbreviations — the Bad version (`u`, `x`, `.a`)
forces the reader to reverse-engineer what the data is, while the typed domain
names read as a sentence:

```python
# Good
def get_active_users(users: list[User]) -> list[User]:
    return [user for user in users if user.is_active]


# Bad
def get_active_users(u):
    return [x for x in u if x.a]
```

Spell words out instead of truncating them — `sb`, `req`, `mgr` save a few
keystrokes at the cost of every future reader pausing to decode them; the full
word is unambiguous:

```python
# Good
sandbox = get_sandbox()
request_manager = SandboxRequestManager(sandbox)


# Bad
sb = get_sandbox()
req_mgr = SandboxRequestManager(sb)
```

Avoid mutable defaults — `items=[]` is evaluated once when the function is
defined, so every call shares and mutates the *same* list and state leaks between
calls; the `None` sentinel gives each call a fresh list:

```python
# Good
def append_to(item: str, items: list[str] | None = None) -> list[str]:
    if items is None:
        items = []
    items.append(item)
    return items


# Bad
def append_to(item, items=[]):
    items.append(item)
    return items
```

Catch specific exceptions and preserve causes — `except Exception: return None`
collapses every failure into an indistinguishable `None` and throws away the
traceback, so the error surfaces somewhere confusing downstream; the Good version
raises a domain error per failure mode and keeps the original cause via
`from error`:

```python
# Good
def load_config(path: Path) -> Config:
    try:
        return Config.from_json(path.read_text())
    except FileNotFoundError as error:
        raise ConfigError(f"Config file not found: {path}") from error
    except json.JSONDecodeError as error:
        raise ConfigError(f"Invalid JSON in config: {path}") from error


# Bad
def load_config(path):
    try:
        return Config.from_json(open(path).read())
    except Exception:
        return None
```

Use context managers for owned resources — the manual `try/finally` is more code
and easy to get wrong (forget the `finally` and the handle leaks); `with`
guarantees the file is closed and shows its lifetime at a glance:

```python
# Good
with path.open(encoding="utf-8") as file:
    content = file.read()


# Bad
file = open(path)
try:
    content = file.read()
finally:
    file.close()
```

Suppress an intentionally-ignored exception with `contextlib.suppress`, not
`try/except: pass` — when the whole point is "ignore this one error and carry on",
the four-line `try/except` with an empty `pass` is control-flow noise that reads
like it might do something; `contextlib.suppress(...)` states the intent in one
line. Reach for it only when the behavior on failure is genuinely "do nothing":

```python
# Good
with contextlib.suppress(KeyError):
    del cache[key]


# Bad
try:
    del cache[key]
except KeyError:
    pass
```

Keep comprehensions simple — the Bad one stacks a transform plus two filters on a
single line, which is hard to scan and easy to misread; reach for a regular loop
once the logic grows past a simple map/filter:

```python
# Good
active_names = [user.name for user in users if user.is_active]


# Bad
result = [item.value * 2 for item in items if item.enabled if item.value > 0]
```

Stream values when an intermediate list is wasteful — `sum([...])` allocates a
throwaway list in memory before summing; the generator expression streams values
straight into `sum` with no allocation:

```python
# Good
total = sum(item.price for item in order.items)


# Bad
total = sum([item.price for item in order.items])
```

Use `is` for `None` and `isinstance()` for type checks — `== None` depends on a
possibly-overridden `__eq__` and tests equality rather than identity, and
`type(x) == dict` rejects valid subclasses and `Mapping` implementations;
`is` / `isinstance` are correct and subclass-friendly:

```python
# Good
if value is None:
    return

if isinstance(payload, Mapping):
    handle_mapping(payload)


# Bad
if value == None:
    return

if type(payload) == dict:
    handle_mapping(payload)
```

Use the walrus operator for conditional-then-use — when a value gates a branch and
is used inside it, bind it right in the condition. That avoids computing the value
twice, and avoids hoisting a standalone line for a variable you only use within the
`if`. (For an assignment-only value that does not gate a branch, a plain `=` is
clearer.)

```python
# Good
if (count := len(data)) > MAX_ITEMS:
    raise ValueError(f"too many items: {count}")


# Bad
if len(data) > MAX_ITEMS:
    raise ValueError(f"too many items: {len(data)}")
```

```python
# Good
if raw := fetch_file(repo=source, path=path):
    return parse(raw)


# Bad
raw = fetch_file(repo=source, path=path)
if raw:
    return parse(raw)
```

Avoid repeated string concatenation — `+=` in a loop rebuilds the entire string
every iteration (O(n²) over the length); `"".join(...)` builds the result in one
pass:

```python
# Good
message = "".join(render_part(part) for part in parts)


# Bad
message = ""
for part in parts:
    message += render_part(part)
```

## Formatting

- Follow the repo formatter. If the repo uses Black, assume an 88-char line length.
- Use two blank lines between top-level definitions.
- Use one blank line between methods in a class.
- Use one blank line between logical sections inside a function body.
- Do not add a blank line immediately after `class Foo:` or `def bar(self):`.
- Do not leave trailing blank lines at the end of files.
- Put trailing commas on multi-line calls and literals.
- Wrap method chains with each method on its own line and leading dots.

```python
members_to_add = (
    self.room.member_set.filter(identifier__in=members)
    .assignable()
    .filter(is_meeting_organiser=True, role=Member.MEMBER)
)
```

## Imports

- Group imports in this order: stdlib, third-party, Django, local.
- Put a blank line between import groups.
- Never use wildcard imports.
- Use `from __future__ import annotations` plus a `TYPE_CHECKING` guard for imports needed only at type-check time.
- Defer circular imports to function bodies when needed; never hide circular imports with `try/except ImportError`.
- Keep `__init__.py` boring. Export only stable public APIs, and define `__all__` only when the package API needs it.
- Avoid module-level setup that opens sockets, reads files, mutates settings, or configures logging as an import side effect.
- Alias stdlib `timezone` as `dt_timezone` when Django's `timezone` is used in the same file.
- Import subpackage exceptions as a namespace when using several of them.
- Instruction modules are imported under a short alias: `from . import instructions as ins`.
- Prefer `import charter_sdk as sdk` instead of importing many names directly.

```python
from __future__ import annotations

import contextlib
from datetime import timezone as dt_timezone
from typing import TYPE_CHECKING

from django.utils import timezone

from . import exceptions
from . import instructions as ins

if TYPE_CHECKING:
    from .breaker import CircuitBreaker


def schedule_search_index_update(document):
    from global_search import services

    services.schedule_document_update(document)
```

## Naming

| Subject | Convention |
| --- | --- |
| Variables, functions, methods | `snake_case` |
| Classes | `PascalCase` |
| Custom context managers | `snake_case` |
| Constants | `UPPER_SNAKE_CASE` |
| Private helpers | `_leading_underscore` |
| Lifecycle hooks | `on_<event>` |
| Task wrappers | `schedule_*` |
| Accessors / factories | `get_*` |
| Boolean properties | `is_*` / `has_*` |
| Test classes | `<Subject><Behavior>Tests` |
| Test methods | `test_<what>_<condition>` |
| Patch target constants in tests | `MODULE = "dotted.module.path"` |
| Builtin shadow avoidance | trailing underscore, e.g. `type_`, `id_`, `input_` |

## Returns And Control Flow

- Functions that produce a value use explicit `return <value>` at the end.
- Guard clauses at the top use bare `return`.
- Void functions fall off at the end.
- Prefer EAFP for narrow operations where the failure mode is expected and local.
- Prefer explicit guards for external input validation and branchy domain rules.
- Use `try/except/else`; success-path code belongs in `else`, not after the `except`.
- Use `finally` for cleanup that must always run.
- Use `contextlib.suppress()` for intentionally ignored exceptions when behavior stays the same.
- Put comments about an `if` branch inside the branch, not above the `if`.
- When a defensive value `or ""`, `or 0`, `or {}` is paired with a schema-required field, drop the fallback. The `or` makes the failure mode silent (empty string flows downstream) instead of loud (`KeyError` at the actual bug). Fallbacks belong only where the value really might be absent.

```python
def update_allowed_editors(self, allowed_editor_ids):
    if not allowed_editor_ids:
        self.allowed_editors.clear()
        return

    members_to_add = (
        self.room.member_set.filter(identifier__in=allowed_editor_ids)
        .filter(is_meeting_organiser=True, role=Member.MEMBER)
    )
    self.allowed_editors.set(members_to_add, clear=True)


try:
    instance.hard_delete()
except ProtectedError:
    logger.error("Deleting failed. Object is still referenced.")
else:
    logger.info("Deleted.")
```

## Strings And Comments

- Use f-strings for normal string formatting.
- Use `%s`-style formatting in exception message strings when that is the local style.
- Leave older logger calls using `%s` formatting unless touching that line for a reason.
- Use `# nosec` on sensitive-looking string literals in tests.
- Comments explain why, never what.
- If removing the comment would not confuse a future reader, do not write it.
- Use `# NOTE:` for architectural caveats.
- Use `# FIXME:` and `# TODO:` only with a reason, optionally a ticket number.
- Use numbered inline step comments for sequential validation phases.
- Methods that directly map to an external protocol may use a docstring like `"""Implements s3.PutObject"""`.
- Use inline `->` examples in docstrings for non-obvious pure utility functions.
- Test methods should have concise one-line docstrings that complete the behavioral story with the method name.
- Do not add docstrings elsewhere unless they add information the code does not already make obvious.

```python
# 1. Decode token and check payload
try:
    payload = jwt.decode(token, conf.PUBLIC_KEY, algorithms=["RS256"])
except exceptions.ExpiredSignatureError:
    return False, None

# 2. Compare identifiers
try:
    file_id = payload["file"]
except KeyError:
    return False, None
```

## Logging

- Use a module-level logger.
- In `tasks.py`, use `get_task_logger(__name__)` from `celery.utils.log`.
- Everywhere else, use `logging.getLogger(__name__)` unless the file already uses `structlog`.
- New code may use `structlog` when that is the repo convention; the logger variable is `log`, not `logger`.
- Do not convert existing `logging.getLogger(__name__)` callsites to `structlog` unless substantially touching the file.
- Use `.exception()` inside `except` blocks when logging an exception with traceback.
- Use `.error()` outside `except` blocks for error conditions or deprecated code paths triggered at runtime.
- Build structured log context before the call and pass it under `extra={"data": data}` for stdlib logging.
- For `structlog`, pass context as keyword arguments.
- Prefix stateful object logs with `[ContextName(identifier)] message.`.
- For slug-identified objects, `[slug] message.` is enough.

```python
logger = logging.getLogger(__name__)

log_extra = {
    "file": document_file.id_str,
    "user_id": document_file.created_by_id,
}
logger.info(
    "Serving %s from storage %d.",
    document_file.id_str,
    backend.storage.pk,
    extra={"data": log_extra},
)

try:
    client.upload(document)
except APIException as error:
    logger.exception("Upload failed.")
    raise error
```

```python
import structlog

log = structlog.get_logger()

log.info("No dispatch slots available", active_count=active_count, limit=limit)
```

## Exceptions

- Raise specific exceptions with useful messages; do not hide failures silently.
- If custom exceptions are needed, define them in `exceptions.py` unless the repo has a different established pattern.
- Use `assert` for internal preconditions and invariants, never for external input validation.
- Use `raise X from error` for domain re-raises so the cause is preserved.
- In retry loops, retain the last error and raise the final domain error from it.
- Bare `except Exception:` is only acceptable at top-level handlers where any error becomes a failure response.
- Use named exception tuples with a why-comment when multiple exception types are intentionally grouped.
- For API clients, prefer status-code-to-exception dicts over long `if/elif` chains.
- Custom exception classes may carry `text` and optional `status_code`; `__str__` assembles the message.
- Use one final `if error_message:` block when several branches can produce a failure message.

```python
exception = None
for storage in storages:
    try:
        file_content = backend.open(self.id_str)
    except backend.read_exceptions as error:
        exception = error
    else:
        return file_content
raise ManagedFileException("Unable to open file from any backend.") from exception
```

```python
class ApiError(Exception):
    def __init__(self, text: str, status_code: int | None = None):
        super().__init__(text)
        self.text = text
        self.status_code = status_code

    def __str__(self):
        message = "API request failed"
        if self.status_code:
            message += f" ({self.status_code})"
        return f"{message}: {self.text}"
```

## Classes And Services

- Method order: constants, `__init__`, class/static methods, properties/cached properties, regular methods, private helpers.
- Use `@cached_property` for expensive computed values.
- Use plain `get_client()` factories for refreshable connections.
- Abstract task base classes use class attributes, not Python ABC.
- Pure interface stubs use `ABC`, `@abstractmethod`, and `...`; put `# pragma: no cover` on the `def` line.
- Empty-body subclasses expected to remain body-free use inline `...`.
- Use `model = None` / `bucket_name = None` sentinels for required subclass attributes when all methods are classmethods and ABC overhead is not useful.
- Use `get_client_kwargs()` plus `get_client()` for composable client construction.
- Use class-level mapping dicts for type-keyed dispatch with a safe default.
- `__repr__` on non-model wrapper objects should include class name and string value.
- Service `create()` methods may use `params.setdefault("field", value)` when caller-provided values should win.
- Use class-based decorators only when the decorator needs durable state; otherwise prefer function decorators.

```python
class BaseAssetServices:
    model = None
    bucket_name = None


class ObjectStorageAssetServices(BaseAssetServices):
    model = Asset
    bucket_name = settings.OBJECT_STORAGE_ASSETS_BUCKET


class FileRange:
    BACKEND_MAPPING = {
        LocalFileSystem: LocalFileSystemRangeBackend,
        S3: S3RangeBackend,
    }

    @classmethod
    def map_backend(cls, original_backend) -> BaseRangeBackend:
        return cls.BACKEND_MAPPING.get(
            original_backend.__class__,
            DefaultRangeBackend,
        )(original_backend)
```

## API Clients

When writing an internal HTTP client for an owned, stable service contract:

- Prefer a thin wrapper over an adapter layer.
- The client should express endpoints, auth, transport errors, and status-to-exception mapping.
- If response shape matches the consumer-facing model, construct typed containers directly with `Model(**payload)`.
- Keep wire values as wire values unless richer behavior is needed.
- Keep stable service configuration on the class or module when it is not meant to vary per instance.
- Avoid generic helper parameters like `expected_status` unless they remove repeated, meaningful logic.
- Preserve explicit error boundaries and let payload construction fail loudly if the owned service contract drifts.
- For external HTTP clients, store a `requests.Session` on the instance, initialize it in `_get_session()`, and route calls through `_request(method, endpoint, *, json=None)`.

```python
class ExternalApiClient:
    exceptions = {
        400: exceptions.ExternalAPI400,
        404: exceptions.ExternalAPI404,
        503: exceptions.ExternalAPIUnavailable,
    }

    def __init__(self, api_key: str, api_url: str):
        self.api_key = api_key
        self.base_url = api_url
        self.session: requests.Session = self._get_session()

    def _get_session(self) -> requests.Session:
        session = requests.Session()
        session.headers.update({"Authorization": f"Bearer {self.api_key}"})
        return session

    def _request(self, method: str, endpoint: str, *, json: dict | None = None) -> dict:
        url = urljoin(self.base_url, endpoint)
        try:
            response = self.session.request(method=method, url=url, json=json, timeout=10)
        except Exception as error:
            raise ApiError(text=str(error)) from error

        if response.status_code in self.exceptions:
            raise self.exceptions[response.status_code](response=response)
        if response.ok:
            return response.json()
        raise ApiError(status_code=response.status_code, text=response.text)
```

## Defensive Parsing Discipline

`dict.get()` is for genuinely optional fields, not for hiding programming mistakes.

Use direct subscripting (`d["key"]`) when:
- The upstream schema (GraphQL non-null `!`, JSON Schema `required`, OpenAPI required, your own Pydantic model) guarantees the field exists.
- The dict is one you constructed yourself in this codebase.
- Failure to find the key means a real contract bug — let it surface as `KeyError`.

Use `.get()` when:
- The upstream schema marks the field optional/nullable.
- The dict comes from untrusted input (webhooks, user-supplied YAML/JSON, HTTP headers).
- The field is conditionally present based on response state (e.g., a check's `conclusion` is null until it completes).
- You are reading a Python-level optional container like a cache, env, or sparse config.

Anti-patterns to remove on sight:
- `str(d.get("id") or "")` for a schema-required `id` — direct `d["id"]`.
- `nodes = d.get("foo", {}).get("nodes", [])` for required GraphQL connection fields.
- Helper functions like `issue_id(issue)` whose body is `str(issue.get("id") or "")` — these are not abstractions, they are bug-hiders.
- `cast(list[object], payload.get("findings", []))` against your own JSON Schema's `required` list.
- Redundant `str(payload["body"])` casts when the schema declares `body: String!`.

When refactoring: a `.get()` with a default that "can never be hit in practice" is a comment lying as code. Either it can be hit (then handle it explicitly), or it can't (then use `[]`).

## Concurrency

- Use concurrency only for a specific bottleneck; do not add it speculatively.
- Use async I/O when the surrounding stack is already async or when concurrency is central to the feature.
- Use threads for blocking I/O at clear boundaries.
- Use processes only for CPU-bound work that is large enough to justify serialization and orchestration overhead.
- Keep concurrent result ordering explicit. If order matters, return ordered containers rather than relying on completion order.
- Preserve individual task failures unless the caller explicitly wants best-effort behavior.
- Avoid `asyncio.gather(..., return_exceptions=True)` unless exception values are part of the returned contract.

## Service App Layout (non-Django)

For non-Django Python services, follow these conventions:

- Project-wide singletons live at the package root, not in subpackages:
  - `cli.py` — CLI entry point
  - `broker.py` — task broker + scheduler instances
  - `database.py` — engine factory, session factory, transaction helpers
  - `config.py` — `Settings` + `load_settings()`
- Subpackages contain only their domain: `api/`, `engine/`, `harnesses/`, `integrations/`, `scoping/`, `storage/`, etc.
- Per-subpackage files mirror the Django app convention (see `django.md` → Django App Layout):
  - `datastructures.py` — dataclasses, `NamedTuple`s, enums, frozen value objects (Django equivalent: `models.py` + `enums.py`)
  - `tasks.py` — background task definitions
  - `protocol.py` — `Protocol` interface definitions
  - Stores/repositories — one file per domain entity (`job_store.py`, `scope_run_store.py`)
- Never put dataclasses or enums inline with the functions that use them. If a subpackage has any pure data shapes, it has a `datastructures.py`.
- Stores/repositories belong in the data subpackage (`storage/`), but the engine plumbing they sit on top of (sessions, transactions, pragmas) is project-wide and lives at the root.
