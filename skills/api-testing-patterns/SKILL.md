---
name: api-testing-patterns
description: API test automation framework — OOP architecture (base classes, service layer, fixtures hierarchy, markers, parallel execution) plus infrastructure (httpx client wrapper, Pydantic validation, test data factories, polling/retry, schema/contract testing). Use when designing or writing API test suites.
origin: custom
---

# API Test Automation Patterns

Patterns for building maintainable, scalable API test suites with pytest, httpx, Pydantic, and Allure. Covers both the **test architecture** (OOP layering) and the supporting **infrastructure** (clients, validators, factories, waiters).

## When to Activate

- Designing test framework architecture
- Writing new API test suites (REST, GraphQL)
- Building reusable HTTP client wrappers
- Validating API responses against schemas
- Generating test data with factories
- Implementing retry/polling for async operations
- Setting up pytest infrastructure (conftest, fixtures, markers, parallel runs)
- Reviewing test code for structure and isolation

## Architecture Overview

A test suite layers like this:

```
tests/            -> test classes (inherit BaseTest), assert behavior
  └─ service layer (UsersAPI, AuthAPI ...) -> one method per endpoint, @allure.step
       └─ HTTPClient -> httpx wrapper with logging + Allure attachments
            └─ Settings -> env-based config
helpers/          -> DataGenerator, Waiter, ResponseValidator, Assertions
```

Tests never call `httpx` directly — they go through a service class. Service classes never build config — they take an injected `HTTPClient`. This keeps tests readable and the HTTP details in one place.

## RULE: No Bare Functions

Every test MUST be inside a class. This is non-negotiable — it gives each test shared setup, a clear feature grouping, and a place to hang fixtures.

```python
# WRONG -- procedural, no encapsulation
def test_create_user():
    response = httpx.post("/users", json={"email": "a@b.com"})
    assert response.status_code == 201

# CORRECT -- OOP, inherits BaseTest, uses service class
@allure.feature("User Management")
class TestCreateUser(BaseTest):
    def test_create_user_returns_201(self):
        data = self.gen.user()
        response = self.users_api.create_user(data)
        assert response.status_code == 201
```

Mandatory test structure: **Arrange-Act-Assert**.

## Base Test Class

```python
import pytest
import allure
from framework.clients.http_client import HTTPClient
from framework.config.settings import Settings
from framework.helpers.data_generator import DataGenerator


class BaseTest:
    """Base class for ALL test classes."""

    client: HTTPClient
    settings: Settings
    gen: type[DataGenerator]

    @pytest.fixture(autouse=True)
    def _setup_base(self, http_client: HTTPClient, settings: Settings):
        """Inject shared dependencies."""
        self.client = http_client
        self.settings = settings
        self.gen = DataGenerator


class BaseAuthenticatedTest(BaseTest):
    """Base for tests requiring authentication."""

    @pytest.fixture(autouse=True)
    def _setup_auth(self, authenticated_client: HTTPClient):
        self.client = authenticated_client
```

## HTTP Client Wrapper (httpx)

httpx is preferred over requests: native async, HTTP/2, granular timeouts, full type hints, and a requests-like API.

```python
import httpx
import allure
import logging
from framework.config.settings import Settings

logger = logging.getLogger(__name__)


class HTTPClient:
    def __init__(self, settings: Settings, token: str | None = None):
        headers = {"Content-Type": "application/json", "Accept": "application/json"}
        if token:
            headers["Authorization"] = f"Bearer {token}"

        self._client = httpx.Client(
            base_url=settings.BASE_URL,
            headers=headers,
            timeout=httpx.Timeout(
                connect=5.0,
                read=settings.REQUEST_TIMEOUT,
                write=5.0,
                pool=5.0,
            ),
        )

    @allure.step("{method} {url}")
    def request(self, method: str, url: str, **kwargs) -> httpx.Response:
        response = self._client.request(method, url, **kwargs)
        self._log(method, url, response)
        self._attach_allure(method, url, response)
        return response

    def get(self, url: str, **kwargs) -> httpx.Response:
        return self.request("GET", url, **kwargs)

    def post(self, url: str, **kwargs) -> httpx.Response:
        return self.request("POST", url, **kwargs)

    def put(self, url: str, **kwargs) -> httpx.Response:
        return self.request("PUT", url, **kwargs)

    def patch(self, url: str, **kwargs) -> httpx.Response:
        return self.request("PATCH", url, **kwargs)

    def delete(self, url: str, **kwargs) -> httpx.Response:
        return self.request("DELETE", url, **kwargs)

    def _log(self, method: str, url: str, response: httpx.Response):
        logger.info(f"{method} {response.request.url} -> {response.status_code} ({response.elapsed.total_seconds():.2f}s)")

    def _attach_allure(self, method: str, url: str, response: httpx.Response):
        allure.attach(str(response.request.url), "URL", allure.attachment_type.TEXT)
        if response.request.content:
            allure.attach(response.request.content.decode(), "Request", allure.attachment_type.JSON)
        allure.attach(response.text, f"Response [{response.status_code}]", allure.attachment_type.JSON)

    def close(self):
        self._client.close()
```

## API Service Layer

One service class per resource. One method per endpoint, each wrapped in `@allure.step`.

```python
class BaseAPIClient:
    """Base for all API service classes."""

    def __init__(self, client: HTTPClient):
        self.client = client


class UsersAPI(BaseAPIClient):
    ENDPOINT = "/api/v1/users"

    @allure.step("POST /users — Create user: {data.email}")
    def create_user(self, data: CreateUserRequest) -> httpx.Response:
        return self.client.post(self.ENDPOINT, json=data.model_dump())

    @allure.step("GET /users/{user_id}")
    def get_user(self, user_id: int) -> httpx.Response:
        return self.client.get(f"{self.ENDPOINT}/{user_id}")

    @allure.step("GET /users — List (page={page})")
    def list_users(self, page: int = 1, per_page: int = 20) -> httpx.Response:
        return self.client.get(self.ENDPOINT, params={"page": page, "per_page": per_page})

    @allure.step("PATCH /users/{user_id}")
    def update_user(self, user_id: int, data: dict) -> httpx.Response:
        return self.client.patch(f"{self.ENDPOINT}/{user_id}", json=data)

    @allure.step("DELETE /users/{user_id}")
    def delete_user(self, user_id: int) -> httpx.Response:
        return self.client.delete(f"{self.ENDPOINT}/{user_id}")
```

## Configuration

```python
from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    BASE_URL: str = "http://localhost:8000"
    ENV_NAME: str = "local"

    # Auth
    TEST_USER_EMAIL: str = "test@example.com"
    TEST_USER_PASSWORD: str = "testpass123"

    # Timeouts
    REQUEST_TIMEOUT: float = 30.0
    POLL_TIMEOUT: float = 60.0
    POLL_INTERVAL: float = 2.0

    model_config = {"env_file": ".env", "env_prefix": "TEST_"}
```

## Fixtures Hierarchy

Root `conftest.py` holds session-scoped infrastructure; module `conftest.py` holds suite-specific services and data.

### Root conftest.py (session-scoped)

```python
# conftest.py
import pytest
from framework.clients.http_client import HTTPClient
from framework.config.settings import Settings


@pytest.fixture(scope="session")
def settings() -> Settings:
    return Settings()

@pytest.fixture(scope="session")
def http_client(settings: Settings) -> HTTPClient:
    client = HTTPClient(settings)
    yield client
    client.close()

@pytest.fixture(scope="session")
def auth_token(http_client, settings) -> str:
    from api.auth_api import AuthAPI
    auth = AuthAPI(http_client)
    resp = auth.login(settings.TEST_USER_EMAIL, settings.TEST_USER_PASSWORD)
    return resp.json()["access_token"]

@pytest.fixture
def authenticated_client(settings, auth_token) -> HTTPClient:
    client = HTTPClient(settings, token=auth_token)
    yield client
    client.close()
```

### Module conftest.py (test-specific)

```python
# tests/test_users/conftest.py
import pytest
from api.users_api import UsersAPI
from framework.helpers.data_generator import DataGenerator


@pytest.fixture
def users_api(http_client) -> UsersAPI:
    return UsersAPI(http_client)

@pytest.fixture
def created_user(users_api: UsersAPI) -> dict:
    """Create a user and return response body. Cleanup after test."""
    data = DataGenerator.user()
    response = users_api.create_user(data)
    user = response.json()
    yield user
    users_api.delete_user(user["id"])  # Cleanup
```

## Test Data Factory

Never hardcode values in tests. Generate everything with Faker, returning typed Pydantic requests.

```python
from faker import Faker
from pydantic import BaseModel, EmailStr, Field

fake = Faker()


class CreateUserRequest(BaseModel):
    email: EmailStr
    password: str = Field(min_length=8)
    name: str


class DataGenerator:
    """Test data factory. NEVER hardcode values in tests."""

    @staticmethod
    def user(**overrides) -> CreateUserRequest:
        defaults = {
            "email": fake.unique.email(),
            "password": fake.password(length=12, special_chars=True),
            "name": fake.name(),
        }
        defaults.update(overrides)
        return CreateUserRequest(**defaults)

    @staticmethod
    def users(count: int, **overrides) -> list[CreateUserRequest]:
        return [DataGenerator.user(**overrides) for _ in range(count)]

    @staticmethod
    def random_string(length: int = 10) -> str:
        return fake.pystr(max_chars=length)

    @staticmethod
    def random_email() -> str:
        return fake.unique.email()

    @staticmethod
    def random_int(min_val: int = 1, max_val: int = 10000) -> int:
        return fake.random_int(min=min_val, max=max_val)
```

## Response Validation with Pydantic

Primary validation path: parse the response body into a Pydantic model.

```python
from pydantic import BaseModel
from httpx import Response


class ResponseValidator:
    """Validate API responses against Pydantic models."""

    @staticmethod
    @allure.step("Validate response against {model.__name__}")
    def validate(response: Response, model: type[BaseModel]) -> BaseModel:
        assert response.status_code < 400, (
            f"Expected success, got {response.status_code}: {response.text[:200]}"
        )
        return model.model_validate(response.json())

    @staticmethod
    @allure.step("Validate list response against {model.__name__}")
    def validate_list(response: Response, model: type[BaseModel]) -> list[BaseModel]:
        data = response.json()
        items = data if isinstance(data, list) else data.get("items", data.get("results", []))
        return [model.model_validate(item) for item in items]

    @staticmethod
    @allure.step("Validate error response: expected {expected_status}")
    def validate_error(response: Response, expected_status: int, contains: str | None = None):
        assert response.status_code == expected_status, (
            f"Expected {expected_status}, got {response.status_code}"
        )
        if contains:
            assert contains.lower() in response.text.lower(), (
                f"Expected '{contains}' in response: {response.text[:200]}"
            )
```

## Parametrization

### Data-driven validation tests

```python
@allure.feature("Input Validation")
class TestUserValidation(BaseTest):

    @pytest.mark.parametrize("field,value,error_field", [
        ("email", "not-email", "email"),
        ("email", "", "email"),
        ("password", "123", "password"),
        ("name", "", "name"),
        ("name", "x" * 256, "name"),
    ], ids=[
        "invalid-email-format",
        "empty-email",
        "short-password",
        "empty-name",
        "name-too-long",
    ])
    @allure.story("Field validation")
    def test_create_user_field_validation(self, field: str, value: str, error_field: str):
        data = self.gen.user(**{field: value})
        response = self.users_api.create_user(data)

        assert response.status_code == 422
        errors = response.json()
        assert any(error_field in str(e) for e in errors.get("detail", []))
```

### Status code matrix

```python
@allure.feature("Authorization")
class TestUserAuthorization(BaseTest):

    @pytest.mark.parametrize("method,endpoint,expected", [
        ("GET", "/api/v1/users", 401),
        ("POST", "/api/v1/users", 401),
        ("GET", "/api/v1/users/1", 401),
        ("DELETE", "/api/v1/users/1", 401),
    ], ids=["list", "create", "get", "delete"])
    @allure.story("Unauthorized access returns 401")
    def test_unauthenticated_returns_401(self, method: str, endpoint: str, expected: int):
        response = getattr(self.client, method.lower())(endpoint)
        assert response.status_code == expected
```

## Markers

```ini
# pyproject.toml
[tool.pytest.ini_options]
markers = [
    "smoke: Quick sanity checks (< 30 seconds total)",
    "regression: Full regression suite",
    "critical: Business-critical flows",
    "negative: Negative/error scenarios",
    "slow: Tests > 10 seconds",
    "flaky: Known flaky tests (quarantined)",
]
```

```python
@pytest.mark.smoke
@pytest.mark.critical
class TestAuthSmoke(BaseAuthenticatedTest):
    def test_login_returns_token(self): ...

    def test_token_refresh_works(self): ...
```

```bash
pytest -m smoke --alluredir=allure-results   # Run smoke suite
pytest -m "not flaky"                         # Everything except flaky
pytest -m "critical and regression"           # Critical regression
```

## Parallel Execution

```bash
uv add pytest-xdist

pytest -n auto --alluredir=allure-results   # Auto-detect CPU count
pytest -n 4                                  # Fixed worker count
```

**Rules for parallel-safe tests:**
- No shared mutable state (class variables, global dicts)
- Each test creates its own entities
- Fixtures with `scope="session"` must be thread-safe
- Use unique identifiers (UUID/Faker) in test data, not sequential IDs

## Polling / Waiter (Replace time.sleep)

```python
import time
import allure
from typing import Callable


class Waiter:
    """Poll until condition is met. NEVER use time.sleep() in tests."""

    @staticmethod
    @allure.step("Wait for condition (timeout={timeout}s, poll={poll_interval}s)")
    def wait_for(
        condition: Callable[[], bool],
        timeout: float = 30.0,
        poll_interval: float = 1.0,
        message: str = "Condition not met",
    ) -> None:
        deadline = time.time() + timeout
        last_error = None
        while time.time() < deadline:
            try:
                if condition():
                    return
            except Exception as e:
                last_error = e
            time.sleep(poll_interval)
        raise TimeoutError(f"{message} after {timeout}s. Last error: {last_error}")

    @staticmethod
    @allure.step("Wait for status {expected_status} on {url}")
    def wait_for_status(
        client: "HTTPClient",
        url: str,
        expected_status: int,
        timeout: float = 30.0,
    ) -> "httpx.Response":
        deadline = time.time() + timeout
        while time.time() < deadline:
            response = client.get(url)
            if response.status_code == expected_status:
                return response
            time.sleep(1.0)
        raise TimeoutError(
            f"Expected status {expected_status} on {url}, "
            f"last got {response.status_code} after {timeout}s"
        )
```

## Retry Decorator

```python
import functools
import time


def retry(max_attempts: int = 3, delay: float = 1.0, backoff: float = 2.0, exceptions: tuple = (Exception,)):
    """Retry decorator for flaky operations (NOT for masking real failures)."""
    def decorator(func):
        @functools.wraps(func)
        def wrapper(*args, **kwargs):
            last_exc = None
            current_delay = delay
            for attempt in range(max_attempts):
                try:
                    return func(*args, **kwargs)
                except exceptions as e:
                    last_exc = e
                    if attempt < max_attempts - 1:
                        time.sleep(current_delay)
                        current_delay *= backoff
            raise last_exc
        return wrapper
    return decorator
```

## Schema / Contract Testing

When you want to assert the raw response shape (not just that it parses into a model), validate against an explicit JSON Schema.

```python
import allure
from jsonschema import validate, ValidationError


class SchemaValidator:

    @staticmethod
    @allure.step("Validate JSON schema for {schema_name}")
    def validate_schema(response_json: dict, schema: dict, schema_name: str = "response"):
        try:
            validate(instance=response_json, schema=schema)
        except ValidationError as e:
            allure.attach(str(e), "Schema Validation Error", allure.attachment_type.TEXT)
            raise AssertionError(f"Schema validation failed for {schema_name}: {e.message}")


# Usage in test
class TestUserSchema(BaseTest):
    USER_SCHEMA = {
        "type": "object",
        "required": ["id", "email", "name", "created_at"],
        "properties": {
            "id": {"type": "integer"},
            "email": {"type": "string", "format": "email"},
            "name": {"type": "string", "minLength": 1},
            "created_at": {"type": "string", "format": "date-time"},
        },
        "additionalProperties": False,
    }

    @allure.story("Response matches schema")
    def test_get_user_matches_schema(self, created_user):
        response = self.users_api.get_user(created_user["id"])
        SchemaValidator.validate_schema(response.json(), self.USER_SCHEMA, "User")
```

## Assertions

`ResponseValidator` covers the common cases. Use the `Assertions` helpers when you want Allure-stepped, message-rich checks, and `SoftAssertions` when you want to collect several field failures before raising.

```python
import allure
from framework.models.response_models import ErrorResponse


class Assertions:
    """Custom assertion helpers with Allure integration."""

    @staticmethod
    @allure.step("Assert status code is {expected}")
    def assert_status(response, expected: int):
        assert response.status_code == expected, (
            f"Expected {expected}, got {response.status_code}. "
            f"Body: {response.text[:200]}"
        )

    @staticmethod
    @allure.step("Assert response matches schema {model.__name__}")
    def assert_schema(response, model: type):
        """Validate response body against Pydantic model."""
        return model.model_validate(response.json())

    @staticmethod
    @allure.step("Assert error response contains: {expected_detail}")
    def assert_error(response, expected_status: int, expected_detail: str | None = None):
        assert response.status_code == expected_status
        if expected_detail:
            error = ErrorResponse.model_validate(response.json())
            assert expected_detail in error.detail


class SoftAssertions:
    """Collect multiple assertion failures before raising."""

    def __init__(self):
        self._failures: list[str] = []

    def check(self, condition: bool, message: str):
        if not condition:
            self._failures.append(message)

    def check_equal(self, actual, expected, field: str):
        if actual != expected:
            self._failures.append(f"{field}: expected {expected!r}, got {actual!r}")

    def assert_all(self):
        if self._failures:
            allure.attach(
                "\n".join(f"- {f}" for f in self._failures),
                "Soft Assertion Failures",
                allure.attachment_type.TEXT,
            )
            raise AssertionError(f"{len(self._failures)} assertion(s) failed:\n" + "\n".join(self._failures))


# Usage
class TestUserFields(BaseTest):
    def test_user_fields(self, created_user):
        response = self.users_api.get_user(created_user["id"])
        body = response.json()

        soft = SoftAssertions()
        soft.check_equal(body["email"], created_user["email"], "email")
        soft.check_equal(body["name"], created_user["name"], "name")
        soft.check("id" in body, "Response must contain 'id'")
        soft.check("created_at" in body, "Response must contain 'created_at'")
        soft.assert_all()
```

## Quick Reference

| Pattern | Purpose |
|---------|---------|
| `BaseTest` / `BaseAuthenticatedTest` | All test classes inherit from these |
| `BaseAPIClient` + service classes | One method per endpoint, `@allure.step` |
| `HTTPClient` | httpx wrapper with logging + Allure attachments |
| `Settings` | Environment-based config |
| `conftest.py` hierarchy | Root (session) -> module -> suite |
| `DataGenerator` | Faker-based test data factory (never hardcode) |
| `ResponseValidator` | Pydantic-based response validation (primary) |
| `Assertions` / `SoftAssertions` | Allure-stepped + collected assertion helpers |
| `SchemaValidator` | JSON Schema contract testing |
| `Waiter` | Polling instead of `time.sleep()` |
| `retry()` | Retry flaky operations (not tests!) |
| `@pytest.mark.parametrize` | Data-driven testing |
| Markers + `pytest -n auto` | Suite selection and parallel execution |
| Arrange-Act-Assert | Mandatory test structure |
