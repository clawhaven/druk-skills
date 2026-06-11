---
name: tdd
description: Test-driven development with a vertical red-green-refactor loop. Use when the user asks for TDD, red-green-refactor, test-first implementation, behavior-focused tests, or a feature/bug fix where the public interface and regression behavior should drive the code.
origin: mattpocock/skills
---

# Test-Driven Development

Use one vertical slice at a time: one failing behavior test, the minimal implementation, then refactor while green.

Core principle: tests should verify behavior through public interfaces, not implementation details.

## Before Coding

Read local instructions and existing test patterns first.

For Python work, also use `python-house-rules`, plus `pytest-django-patterns` for Django tests or `api-testing-patterns` for API test suites.

Clarify the public interface and highest-value behaviors when they are ambiguous. If the user has already given enough direction, proceed and state assumptions briefly.

## Avoid Horizontal Slices

Do not write all tests first and then all implementation. That locks in imagined behavior and brittle test structure too early.

Use tracer bullets instead:

```text
RED -> GREEN: behavior 1
RED -> GREEN: behavior 2
RED -> GREEN: behavior 3
REFACTOR while green
```

## Per-Cycle Rules

1. Choose one observable behavior.
2. Write one failing test through the public interface.
3. Run it and confirm it fails for the expected reason.
4. Write only enough code to pass.
5. Run the focused test.
6. Repeat for the next behavior.
7. Refactor only while tests are green.

## Test Quality

Good tests:

- describe behavior users or callers care about
- use public APIs or durable integration seams
- survive internal refactors
- mock only true system boundaries
- fail for meaningful behavioral regressions

Bad tests:

- assert private methods or internal calls
- mock modules/classes you own just to make wiring easy
- verify call order unless call order is the behavior
- duplicate implementation details in test setup

Read the references as needed:

- [references/tests.md](references/tests.md) for behavior-focused test examples.
- [references/mocking.md](references/mocking.md) for mock boundaries.
- [references/interface-design.md](references/interface-design.md) for testable interfaces.
- [references/deep-modules.md](references/deep-modules.md) for small-interface design.
- [references/refactoring.md](references/refactoring.md) for green-phase cleanup prompts.

## Completion

Before declaring done:

- the focused tests pass
- the relevant repo-standard verification has been run when feasible
- no speculative behavior remains
- final summary reports exactly what was and was not run
