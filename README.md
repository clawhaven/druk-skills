# druk-skills

A private, curated agent skill distribution for Paulo's own usage, for Claude Code and Codex.

The repo holds a pruned, internally consistent set of skills in `skills/` — one directory per skill, each with a `SKILL.md` entry point and optional `references/` files for progressive disclosure. It is a working distribution of skills worth keeping together, not a mirror of public skill collections.

Where each skill came from (and what was merged or removed along the way) is documented in [SOURCES.md](SOURCES.md).

## What's inside

- **Python house rules** — `python-house-rules`, the authoritative personal style skill (core + references). Takes precedence over the generic skills when both apply.
- **Python/Django stack** — Django architecture/models/verification, pytest, Celery, FastAPI, Pydantic, SQLAlchemy, async HTTP, API test automation, migrations, Postgres, Docker.
- **Workflow** — `tdd`, `grill-with-docs`, `to-issues`, `systematic-debugging`, `code-quality`, `docs-sync`.
- **Frontend** — Vercel's `next-best-practices`, `next-cache-components`, `web-design-guidelines`.

## Install

Skills are discovered from your agent's skills directory — `~/.claude/skills` for Claude Code, `~/.codex/skills` for Codex.

### Option 1: symlink installer (recommended)

Links each skill individually and skips any target that already exists; repo changes show up immediately.

```bash
# Claude Code (default target ~/.claude/skills)
./scripts/link-skills.sh

# Codex
CODEX_SKILLS_DIR=~/.codex/skills ./scripts/link-skills.sh

# Any other target
AGENT_SKILLS_DIR=/custom/path ./scripts/link-skills.sh
```

### Option 2: symlink the whole skills directory

```bash
ln -sfn "$(pwd)/skills" ~/.claude/skills   # or ~/.codex/skills
```

### Option 3: copy

```bash
mkdir -p ~/.claude/skills && cp -R skills/* ~/.claude/skills/
```

### Verify

```bash
find ~/.claude/skills -maxdepth 1 -mindepth 1 | sort
```

Then restart the agent or start a new session so it discovers the skills.

## Updating

- Symlink installs pick up repo changes automatically.
- Copy installs need changed skill folders re-copied, e.g. `cp -R skills/django-patterns ~/.claude/skills/`.

## Curation rule

Only keep skills here if they are:

- clearly useful in real workflows
- current enough to trust
- not duplicate with stronger local alternatives
- worth maintaining as part of a personal setup

## Provenance

See [SOURCES.md](SOURCES.md) for upstream origins, copied paths, removal rationale, and licensing notes.
