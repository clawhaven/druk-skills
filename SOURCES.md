# Sources

This repo contains curated copies of selected public skills.

## `web-design-guidelines`

- Source repo: `https://github.com/vercel-labs/agent-skills`
- Source path: `skills/web-design-guidelines`
- Copied on: 2026-03-30
- Notes: kept as-is for now

## `next-best-practices`

- Source repo: `https://github.com/vercel-labs/next-skills`
- Source path: `skills/next-best-practices`
- Copied on: 2026-03-30
- Notes: kept as-is for now

## `next-cache-components`

- Source repo: `https://github.com/vercel-labs/next-skills`
- Source path: `skills/next-cache-components`
- Copied on: 2026-03-30
- Notes: kept as-is for now

## Imported from `manikosto/claude-code-python-stack`

- Source repo: `https://github.com/manikosto/claude-code-python-stack`
- Source root: `skills/`
- Copied on: 2026-03-30
- Notes: imported broadly, then pruned to the retained set below

Retained skills:
- `api-testing-patterns`
- `async-http-patterns`
- `celery-patterns`
- `code-quality`
- `database-migrations`
- `django-patterns`
- `django-verification`
- `docker-patterns`
- `fastapi-patterns`
- `postgres-patterns`
- `pydantic-patterns`
- `pytest-django-patterns`
- `sqlalchemy-patterns`

Also imported and since removed: `python-patterns`, `django-tdd`, `python-testing`,
`pytest-oop-patterns`, `deployment-patterns`, `django-security`, `redis-patterns`
(see the Removed section below for rationale), plus `allure-reporting` and
`clickhouse-io`, which were dropped in earlier pruning passes before removals were
logged individually.

## Imported from `kjnez/claude-code-django`

- Source repo: `https://github.com/kjnez/claude-code-django`
- Source root: `.claude/skills/`
- Copied on: 2026-03-30
- Notes: imported broadly, then pruned to the retained set below

Retained skills:
- `django-models`
- `docs-sync`
- `systematic-debugging`

Also imported and since removed: `django-templates`, `django-security`,
`django-forms`, `django-extensions` (see the Removed section below for rationale).
`celery-patterns` and `django-patterns` also appear in the manikosto manifest; the
`celery-patterns` overlap was resolved in manikosto's favor (see Overlap note).
`htmx-patterns`, `onboard`, `pr-review`, `pr-summary`, `skill-creator`, `ticket`,
and `worktree-commit-merge` were dropped in earlier pruning passes before removals
were logged individually.

## Personal local skills

### `python-house-rules`

- Source: Paulo's local Codex skill at `~/.codex/skills/python-house-rules`
- Copied on: 2026-05-16
- Notes: personal standing Python, Django, DRF, testing, typing, and service-structure rules. This should take precedence over generic Python style skills when both are relevant.

## Imported and adapted from `mattpocock/skills`

- Source repo: `https://github.com/mattpocock/skills`
- Copied on: 2026-05-16
- Notes: adapted for Codex metadata, this repo's Linear-oriented workflow, and concise progressive disclosure. Content was not copied as a full mirror.

Imported skills:
- `grill-with-docs`
  - Source path: `skills/engineering/grill-with-docs`
  - Included references: `ADR-FORMAT.md`, `CONTEXT-FORMAT.md`
- `tdd`
  - Source path: `skills/engineering/tdd`
  - Included references: `deep-modules.md`, `interface-design.md`, `mocking.md`, `refactoring.md`, `tests.md`
- `to-issues`
  - Source path: `skills/engineering/to-issues`
  - Notes: adapted issue-tracker language to prefer Linear when available.

## Removed (merges and prunes)

### `python-patterns`

- Source repo: `https://github.com/manikosto/claude-code-python-stack`
- Source path: `skills/python-patterns`
- Copied on: 2026-03-30
- Removed on: 2026-05-16
- Notes: useful idioms, contrast examples, concurrency guidance, package-export guidance, and anti-patterns were merged into `python-house-rules`; the standalone skill was removed to avoid duplicate generic Python style guidance.

### `django-tdd`

- Source repo: `https://github.com/manikosto/claude-code-python-stack`
- Source path: `skills/django-tdd`
- Copied on: 2026-03-30
- Removed on: 2026-06-09
- Notes: ~80% subsumed by the more complete `pytest-django-patterns`, with TDD methodology already covered by `tdd`. Its unique coverage-targets table and DRF `APIClient` testing examples were merged into `pytest-django-patterns`; the standalone skill was removed to avoid duplicate Django testing guidance.

### `python-testing`

- Source repo: `https://github.com/manikosto/claude-code-python-stack`
- Source path: `skills/python-testing`
- Copied on: 2026-03-30
- Removed on: 2026-06-09
- Notes: generic pytest tutorial (fixtures, parametrization, mocking, async) already covered by `tdd`, `pytest-django-patterns`, and `python-house-rules`. Its only distinct content, `pytest-asyncio` async testing, is already present in `async-http-patterns`; the standalone skill was removed to avoid duplicate generic testing guidance.

### `pytest-oop-patterns`

- Source repo: `https://github.com/manikosto/claude-code-python-stack`
- Source path: `skills/pytest-oop-patterns`
- Copied on: 2026-03-30
- Removed on: 2026-06-09
- Notes: ~55% overlap with `api-testing-patterns` — the two were two halves of one framework (`pytest-oop-patterns` described the OOP test *architecture* and referenced the very `HTTPClient`/`Settings`/`DataGenerator` classes that `api-testing-patterns` *defined* as infra). Merged into a single `api-testing-patterns` skill covering both architecture and infrastructure; the standalone skill was removed.

### `deployment-patterns`

- Source repo: `https://github.com/manikosto/claude-code-python-stack`
- Source path: `skills/deployment-patterns`
- Copied on: 2026-03-30
- Removed on: 2026-06-09
- Notes: thin, generic boilerplate (deployment-strategy table, a Dockerfile byte-for-byte duplicated from `docker-patterns`, a generic GitHub Actions pipeline, a health endpoint, a readiness checklist) — all recall-grade content a model generates on demand, with the genuinely useful pieces already covered elsewhere (`django-verification` for the CI/lint/test/security pipeline, `fastapi-patterns` for health endpoints). Removed; `docker-patterns` retained as the single home for the local multi-service Compose stack.

### `django-templates`

- Source repo: `https://github.com/kjnez/claude-code-django`
- Source path: `.claude/skills/django-templates`
- Copied on: 2026-03-30
- Removed on: 2026-06-09
- Notes: generic scaffolding (template-inheritance blocks, partials/components directory layout, standard tags/filters) — Django-tutorial content with no opinionated or repo-specific rules. Removed during Django-skill pruning.

### `django-security`

- Source repos: `https://github.com/kjnez/claude-code-django`, `https://github.com/manikosto/claude-code-python-stack`
- Source path: `.claude/skills/django-security` / `skills/django-security`
- Copied on: 2026-03-30
- Removed on: 2026-06-09
- Notes: a restatement of Django's own security checklist (SECURE_SSL_REDIRECT, HSTS, CSRF/XSS settings) — mandatory baseline, not opinionated guidance. Any custom security requirements belong in `python-house-rules` as non-negotiable rules. Removed during Django-skill pruning.

### `django-forms`

- Source repo: `https://github.com/kjnez/claude-code-django`
- Source path: `.claude/skills/django-forms`
- Copied on: 2026-03-30
- Removed on: 2026-06-09
- Notes: ~90% covered by `python-house-rules` (ModelForm `clean()`/`add_error()`/`save()` patterns); the only distinct content was a thin HTMX form snippet not worth a standalone skill. Removed during Django-skill pruning.

### `django-extensions`

- Source repo: `https://github.com/kjnez/claude-code-django`
- Source path: `.claude/skills/django-extensions`
- Copied on: 2026-03-30
- Removed on: 2026-06-09
- Notes: a command cheat-sheet for `django-extensions` (`show_urls`, `shell_plus`, `list_model_info`, `sqldiff`) rather than guidance; the key commands are already referenced inline by `systematic-debugging`. Removed during Django-skill pruning.

### `redis-patterns`

- Source repo: `https://github.com/manikosto/claude-code-python-stack`
- Source path: `skills/redis-patterns`
- Copied on: 2026-03-30
- Removed on: 2026-06-09
- Notes: mostly generic Redis usage (connection setup, caching, pub/sub, Django cache config). Two less-trivial patterns (sliding-window/token-bucket rate limiting, distributed lock) were not preserved elsewhere; dropped per request as not part of the active stack.

## Note on django-patterns / django-models

`django-patterns` previously duplicated `django-models`' Custom-QuerySet and N+1 content. That ORM/QuerySet material was removed from `django-patterns` (which now points to `django-models` and stays focused on app architecture: structure, DRF, service layer, middleware). Both skills retained.

## Overlap note

The only actual folder-name overlap in this import set was `celery-patterns`.

That overlap was reviewed manually, and the retained version is:
- `celery-patterns` → from `manikosto/claude-code-python-stack`

Reason: it is materially more complete and mature as a long-lived reference skill than the shorter `kjnez` version.

## Licensing note

These copied skills remain subject to their original upstream licenses and attribution requirements. Before public redistribution, verify each upstream repo license and whether any notices should be preserved in this repo.
