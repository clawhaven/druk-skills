---
name: grill-with-docs
description: Stress-test a plan against the repo's domain language and documented decisions. Use when the user asks to grill, interrogate, sharpen, or validate a plan; when terminology is fuzzy; or when a design needs CONTEXT.md or Notion ADR capture before implementation.
---

# Grill With Docs

Interview the user until the plan is precise enough to implement without guessing. Ask one question at a time. For each question, give your recommended answer and the trade-off behind it.

If a question can be answered by reading the repo, read the repo instead of asking.

## Workflow

1. Read local instructions first: `AGENTS.md`, README, project docs, existing `CONTEXT.md`, `CONTEXT-MAP.md`, and `docs/adr/`.
2. Infer the current project from the working directory, repo name, pyproject/package metadata, AGENTS.md, README, and existing Notion context. If confidence is not high, ask one concise clarifying question before writing durable docs.
3. Identify the domain context involved. If `CONTEXT-MAP.md` exists, use it to locate the relevant glossary. If no glossary exists, create one only after the first durable term is resolved.
4. Walk the design tree one dependency at a time. Start with the decision that blocks the most downstream choices.
5. Challenge vague or overloaded language immediately. Prefer one canonical term and list aliases to avoid.
6. Cross-check claims against code. If the user's description conflicts with implementation, surface the mismatch and ask which should become true.
7. Update docs inline as decisions crystallize. Local glossary updates stay in repo `CONTEXT.md`; ADRs go to the inferred project's Notion ADR area.

## CONTEXT.md

Use `CONTEXT.md` only as a domain glossary. It is not a spec, scratch pad, implementation plan, or changelog.

Read [references/CONTEXT-FORMAT.md](references/CONTEXT-FORMAT.md) before creating or materially changing glossary content.

Capture:

- canonical domain terms
- aliases to avoid
- relationships between terms
- short example dialogue that demonstrates how the terms interact
- resolved ambiguities

Do not capture:

- generic programming concepts
- implementation details
- TODOs
- decisions that belong in ADRs

## ADRs

Offer an ADR only when all three are true:

- The decision is expensive to reverse.
- The choice would be surprising without context.
- There was a real trade-off among viable alternatives.

Read [references/ADR-FORMAT.md](references/ADR-FORMAT.md) before creating an ADR.

Create ADRs in Notion, not in the application repository:

1. Locate the inferred project's Notion page.
2. Find an `ADRs` child page under that project. If it does not exist, create it under the project page.
3. Create one child page per ADR under `ADRs`.
4. Use the title format `NNNN - Short Title`, starting at the next sequence number visible in that ADR area.
5. Keep the ADR concise: context, decision, considered options with trade-offs, and consequences.
6. If Notion tools are unavailable or the project page cannot be identified confidently, ask before writing the ADR anywhere else.

## Output

During the session, keep the user focused on the current unresolved decision. At the end, summarize:

- decisions resolved
- terms added or changed
- ADRs created or intentionally skipped
- remaining open questions
