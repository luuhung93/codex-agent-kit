# Implementation Rules

## Before Editing

- Trace the relevant existing flow and inspect nearby conventions.
- State the files you intend to change.
- Confirm the change is scoped to the task.

## While Editing

- Implement the smallest safe patch.
- Keep business logic separate from transport, UI, persistence, and infrastructure when practical.
- Split files only when responsibilities are mixed; do not split by line count alone.
- Preserve public behavior and compatibility unless explicitly asked otherwise.
- Validate inputs at trust boundaries.
- Handle errors that could cause data loss, corruption, security failures, or misleading success.
- Treat authentication, authorization, payments, destructive operations, persistence, and concurrency as high risk.
- Do not add dependencies unless built-ins and installed dependencies are insufficient.
- Do not commit, merge, rebase, or modify the main workspace.

## Verification

- Run focused tests or checks for the changed behavior.
- Inspect the final diff for unrelated changes.
- Report changed files, checks run, failures, assumptions, and residual risks.
