---
name: django-verification
description: "Verification loop for Django projects: migrations, linting, tests with coverage, security scans, and deployment readiness checks. Use when preparing a Django PR, after major model/migration changes, or before deploying."
origin: ECC
---

# Django Verification Loop

Run before PRs, after major changes, and pre-deploy.

## When to Activate

- Before opening a pull request for a Django project
- After major model changes, migration updates, or dependency upgrades
- Pre-deployment verification

## Verification Pipeline

```bash
# Phase 1: Code Quality
uv run ruff check .
uv run ruff format --check .
uv run pyright
python manage.py check --deploy

# Phase 2: Migrations
python manage.py showmigrations
python manage.py makemigrations --check
python manage.py migrate --plan

# Phase 3: Tests + Coverage
uv run pytest --cov=apps --cov-report=html --cov-report=term-missing --reuse-db

# Phase 4: Security
uv run pip-audit
uv run bandit -r . -f json -o bandit-report.json
python manage.py check --deploy

# Phase 5: Django Commands
python manage.py check
python manage.py collectstatic --noinput --clear
```

## Pre-Deployment Checklist

- [ ] All tests passing
- [ ] Coverage >= 80%
- [ ] No security vulnerabilities
- [ ] No unapplied migrations
- [ ] DEBUG = False in production settings
- [ ] SECRET_KEY properly configured
- [ ] ALLOWED_HOSTS set correctly
- [ ] Static files collected
- [ ] Logging configured
- [ ] HTTPS/SSL configured

## GitHub Actions Example

```yaml
name: Django Verification
on: [push, pull_request]
jobs:
  verify:
    runs-on: ubuntu-latest
    services:
      postgres:
        image: postgres:16
        env:
          POSTGRES_PASSWORD: postgres
    steps:
      - uses: actions/checkout@v4
      - uses: astral-sh/setup-uv@v5
        with:
          python-version: '3.12'
      - run: uv sync
      - run: uv run ruff check . && uv run ruff format --check . && uv run pyright
      - run: uv run bandit -r . && uv run pip-audit
      - env:
          DATABASE_URL: postgres://postgres:postgres@localhost:5432/test
          DJANGO_SECRET_KEY: test-secret-key
        run: uv run pytest --cov=apps --cov-report=xml
```
