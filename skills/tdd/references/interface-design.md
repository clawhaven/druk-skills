# Interface Design For Testability

Good interfaces make behavior tests natural.

## Guidelines

- Accept dependencies instead of creating them internally.
- Return results instead of hiding important effects in mutation.
- Keep the surface area small.
- Prefer explicit domain inputs over generic dictionaries.
- Push complex decisions behind a simple public method.

Small interfaces reduce test count and make regression coverage easier to trust.
