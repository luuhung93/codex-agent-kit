# Implementation Rules

## Scope

- Understand the relevant flow and nearby conventions before editing.
- Implement the smallest safe patch.
- Keep changes scoped to the requested behavior.
- Preserve public contracts unless explicitly asked to change them.

## Structure

- Organize code by feature and responsibility.
- Give each file one primary responsibility.
- Keep feature-specific code inside its feature or module directory.
- Avoid dumping unrelated code into generic `utils`, `helpers`, or `common` modules.
- Keep dependency direction and state ownership explicit.
- Avoid circular dependencies, hidden global state, deep nesting, and god modules.
- Separate business logic from transport, UI, persistence, and infrastructure when practical.

File size is a signal, not a hard rule:

- At 200–300 lines, check cohesion.
- At 300–500 lines, strongly consider splitting by responsibility.
- Over 500 lines, split unless there is a clear reason not to.
- Avoid both giant files and excessive tiny files.

## Correctness

- Validate inputs at trust boundaries.
- Handle errors that could cause data loss, corruption, security issues, or misleading success.
- Preserve authentication, authorization, and destructive-operation safeguards.
- Consider concurrency, idempotency, and transaction boundaries when relevant.
- Avoid premature optimization; address demonstrated or structurally obvious performance risks.

## Validation

- Add or update focused tests when behavior changes and the repository has a test pattern.
- Run the smallest relevant tests, type checks, lint, build, or runtime checks.
- Fix failures caused by the patch; do not hide or bypass them.
- Report changed behavior, validation performed, and residual risks.
