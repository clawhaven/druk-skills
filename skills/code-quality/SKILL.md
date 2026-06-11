---
name: code-quality
description: Run code quality checks (ruff lint, ruff format, pyright, pytest) on a directory of any Python project and report findings by severity. Use when the user wants to audit code quality, check for type errors, lint issues, or run automated checks on a path. Accepts a directory path as argument. Triggers on requests like "check code quality", "run quality checks", "/code-quality apps/".
---

# Code Quality Review

Framework-agnostic quality audit of the Python directory provided by the user. Works for any Python codebase (library, CLI, FastAPI, Django, etc.).

## Instructions

1. **Identify files to review**:
   - Find all `.py` files in the directory
   - Exclude `__pycache__`, generated files, and framework-generated code (e.g. Django migrations)

2. **Run automated checks**:
   ```bash
   uv run ruff check <directory>
   uv run ruff format --check <directory>
   uv run pyright <directory>
   uv run pytest <directory> -v
   ```
   If the project doesn't use `uv`, drop the `uv run` prefix. Substitute the project's configured type checker (`mypy`) or test runner if different.

3. **Manual review checklist** (universal):
   - [ ] No `Any` types without justification
   - [ ] Proper error handling (no silently swallowed exceptions)
   - [ ] Functions/methods do one thing; no dead or duplicated code
   - [ ] Public APIs have type hints and docstrings where non-obvious
   - [ ] No hardcoded secrets or environment-specific values
   - [ ] Tests cover the change; use factories/fixtures, not ad-hoc object creation
   - [ ] No obvious performance traps (unbounded loops, repeated I/O in loops)

4. **If the project uses a web/async framework, also check** (skip what doesn't apply):
   - [ ] Database N+1 access avoided (e.g. Django `select_related`/`prefetch_related`, SQLAlchemy eager loading)
   - [ ] Request handlers return correct HTTP status codes
   - [ ] Form/request payloads are validated
   - [ ] Partial-render paths handled (e.g. HTMX `HX-Request` header)
   - [ ] Background tasks (Celery, etc.) are idempotent

5. **Report findings** organized by severity:
   - Critical (must fix)
   - Warning (should fix)
   - Suggestion (could improve)
