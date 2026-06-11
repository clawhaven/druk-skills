# Refactoring Prompts

Refactor only while tests are green.

Look for:

- duplication to extract
- long methods to split behind the same public interface
- shallow modules to combine or deepen
- logic living far from the data or domain concept it belongs to
- primitive obsession that wants a value object
- code revealed as awkward by the new test seam

After each refactor step, rerun the focused tests.
