# ADR Format

ADRs live in Notion under the inferred project's `ADRs` page.

Find the current project from the repo/workspace context before writing. If the project is not clear, ask one concise clarifying question. If the project's Notion page has no `ADRs` child page, create it lazily before creating the ADR.

Use sequential page titles:

```text
0001 - Short Title
0002 - Short Title
```

## Template

```md
Status: accepted

{One to three sentences covering the context, the decision, and why this decision won over the alternatives.}
```

That is enough for most ADRs. The value is recording that a decision was made and why.

## Optional Sections

Use these only when they add real value:

- `Status` frontmatter: `proposed`, `accepted`, `deprecated`, or `superseded by ADR-NNNN`.
- `Considered Options`: when rejected alternatives are worth remembering.
- `Consequences`: when downstream effects are non-obvious.

## When An ADR Qualifies

Create an ADR only when all three are true:

- Hard to reverse.
- Surprising without context.
- The result of a real trade-off.

Good ADR subjects include architectural shape, context boundaries, lock-in technology choices, deliberate deviations from the obvious path, hidden constraints, and non-obvious rejected alternatives.
