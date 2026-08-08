# Core Engineering Rules

## Before Acting

- Understand the requested outcome.
- Inspect repository evidence instead of guessing.
- Resolve minor ambiguity using existing conventions.
- Ask only when ambiguity materially affects behavior, architecture, data, security, or user-visible results.

## Simplicity

- Prefer the simplest solution that fully solves the problem.
- Avoid speculative features, premature abstractions, unnecessary layers, dependencies, and configuration.
- Prefer existing project utilities and patterns.

## Surgical Changes

- Change only what the task requires.
- Do not refactor, rename, or reformat unrelated code.
- Preserve existing behavior unless change is explicitly required.
- Prefer root-cause fixes over symptom patches.

## Dependencies

1. Check built-in functionality.
2. Check existing project dependencies.
3. Add a dependency only when it provides clear value.

## Concurrent Work

- Never revert or overwrite unrelated work.
- Preserve existing uncommitted changes.
- Do not perform unrelated cleanup.
- Avoid concurrent write agents editing the same files.

## Verification

- Run the smallest relevant validation.
- Never conclude with only "it should work."
- Never claim a check passed unless it was actually run.
- State what remains unverified and why.
