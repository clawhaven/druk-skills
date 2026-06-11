---
name: to-issues
description: Break a plan, spec, PRD, or conversation into independently implementable issue-tracker tickets using vertical slices. Use when the user asks to create implementation issues, split work into tickets, convert a plan to Linear or GitHub issues, or prepare work for AFK agents.
origin: mattpocock/skills
---

# To Issues

Turn a plan into thin, independently useful issues. Prefer vertical slices over layer-by-layer tasks.

Use the repo's configured issue tracker. If Linear is available and local instructions do not say otherwise, use Linear. If the project or team is ambiguous, ask one concise clarifying question before publishing.

## Workflow

1. Gather context from the conversation, referenced specs, existing issues, repo docs, `CONTEXT.md`, and ADRs.
2. Explore the codebase only enough to make issue boundaries realistic.
3. Draft vertical slices.
4. Show the draft breakdown for approval unless the user explicitly asked you to create the issues directly.
5. Publish approved issues in dependency order so blocker IDs can be referenced.

## Vertical Slice Rules

Each issue should deliver a narrow but complete path through the system.

Good slices:

- are demoable or verifiable on their own
- cover the necessary integration layers for one behavior
- have concrete acceptance criteria
- minimize coordination between future agents
- use the project's domain language

Avoid horizontal slices such as "add database models", "build API", then "build UI" unless that layer-only task is independently valuable.

## HITL vs AFK

Mark each proposed slice:

- `AFK`: an agent can implement it from the issue without new human judgment.
- `HITL`: needs human design, product, legal, access, or operational judgment before implementation.

Prefer AFK where possible, but do not pretend unresolved decisions are implementable.

## Draft Format

Present proposed slices as a numbered list:

```md
1. Title
   Type: AFK | HITL
   Blocked by: None | slice numbers
   Covers: user stories or source requirements
   Notes: key trade-off or unresolved decision
```

Ask whether the granularity, dependencies, and HITL/AFK labels are right.

## Issue Body Template

```md
## Parent

{Parent issue/spec link, if any}

## What to build

{Concise description of the end-to-end behavior. Avoid fragile file-path instructions unless the path is the durable interface.}

## Acceptance criteria

- [ ] Criterion 1
- [ ] Criterion 2
- [ ] Criterion 3

## Blocked by

{Issue IDs, slice numbers pending publication, or "None - can start immediately."}
```

If a prototype produced a compact state machine, schema, or type shape that captures a decision better than prose, include the trimmed decision-rich snippet and note that it came from a prototype.

Do not close or materially modify a parent issue unless the user explicitly asks.
