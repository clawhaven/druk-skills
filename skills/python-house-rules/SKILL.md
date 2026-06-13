---
name: python-house-rules
description: Use for any Python code change, review, refactor, debugging task, test
  update, or pyproject/tooling edit when the user's standing Python rules should
  be applied consistently across repositories, including Django, DRF, Celery,
  migrations, testing, typing, exceptions, logging, and service structure.
---

# Python House Rules

Apply these rules on every Python task unless the user explicitly overrides them.
When choosing between two valid Python approaches, prefer the approach documented
here. When reviewing code, flag deviations with a short explanation.

These rules take precedence over generic Python/Django style skills when both are
relevant.

## Reference Files

This skill is split for progressive disclosure. The core (this file) always
applies. Before writing or reviewing code, **read the reference file(s) that match
the task** — they hold the detailed rules and the calibration examples:

- `references/python-style.md` — **any non-trivial Python.** PEP 8, typing, style,
  good/bad examples, formatting, imports, naming, control flow, strings/comments,
  logging, exceptions, classes/services, API clients, defensive parsing,
  concurrency, and non-Django service layout.
- `references/django.md` — **Django / DRF / Celery work.** App layout, models,
  querysets/ORM, enums, forms, admin, celery/tasks, signals, migrations & system
  checks, settings, DRF/viewsets, throttling/authz/flags, management
  commands/middleware.
- `references/testing.md` — **writing or reviewing tests.** Testing principles and
  Django test patterns.

When unsure, read `python-style.md` first. For a Django change that also adds
tests, read all three.

## First Pass

Before editing:

- Read the repo's `AGENTS.md` if present.
- Check `pyproject.toml`, formatter config, lint config, pytest config, and type-checker config.
- Match the existing package style and architecture before introducing a new pattern.
- Discover the package layout, dependency direction, and local conventions before editing.

If repo-local rules conflict with these house rules, follow the stricter or more
specific rule and mention the conflict briefly.

## Core Philosophy

- Code should read like prose written by someone who already understands the domain.
- Minimize the time the next reader spends building a mental model.
- Prefer clean current design over compatibility layers unless compatibility is explicitly required.
- Abstractions earn their place by being used three times or more; before that, duplication is often cheaper than indirection.
- Build only what the task asks for. Do not add config knobs, options, alternate code paths, or speculative resilience that were not requested — unused flexibility is complexity no one is paying for. When a "while I'm here" extension is tempting, leave it out (or raise it separately).
- Guard clauses live at the top of functions; main logic lives in the middle.
- Keep functions focused and side effects explicit.
- Reuse existing project patterns before introducing new abstractions or dependencies.
- Be skeptical of generic abstraction layers that only move data around; keep abstractions only where there is real behavioral variation.
- Prefer explicit configuration and visible setup over import-time side effects.
- Prefer explicit wire contracts over defensive parsing for owned service contracts.
- Do not invent resilience for undocumented alternate payload shapes unless the task explicitly requires it.
- Prefer domain-owned path builders and identifiers over settings-driven path glue.
- Avoid projection or mirror data models unless there is a hard product requirement for separate copies.
- Keep I/O, subprocess, network, and database boundaries easy to spot.

## Debugging Rules

- Do root-cause analysis before fixing a bug.
- Do not patch symptoms if the underlying cause is still unclear.
- When the cause is inferred rather than proven, say so explicitly.
- Keep fixes tightly scoped to the root cause.

## Verification

- Prefer the smallest useful verification set first, then broaden if risk is high.
- Run repo-standard checks when feasible and report exactly what ran.
- Typical Python verification is `uv run pytest`, `uv run ruff check`, and formatter check such as `uv run ruff format --check` or the repo's configured equivalent.
- Do not run formatters or linters in rewrite mode unless implementation work calls for it and the user has not restricted edits.
- For Django behavior changes, include migrations checks and focused tests when relevant.

## Decision Defaults

- Greenfield project work can prefer clean breaking changes over compatibility layers when the user has not requested compatibility.
- Preserve backwards compatibility only when the task, repo, or product requirement calls for it.
- Prefer incremental patches over large rewrites unless a cleaner design clearly requires a wider change.
- Leave concise comments only where the code would otherwise be hard to follow.
- Prefer upstream-system state of record over local mirror state. If GitHub/Linear/Slack can store the flag, label, or field that answers "has X happened?", use it. Local DB rows are for state we genuinely own: audit, retries, in-flight work. Do not maintain a hash/snapshot/cached-projection of upstream content just to compute "has this changed" — let the upstream system own that.
- Avoid intermediate projection types between an upstream response and the place that uses the data. A `LinearIssueSnapshot` dataclass built from a Linear GraphQL dict, then consumed by functions that read the same fields, is one layer of indirection too many. Operate on the upstream dict directly or model it as a typed object that lives at the boundary.

## Final Response Expectations

In final responses for Python work:

- Lead with what changed.
- Mention verification status.
- Call out important assumptions.
- Surface risks or follow-ups if something could not be fully validated.
- Keep the response short and useful.
