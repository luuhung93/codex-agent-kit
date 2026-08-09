# Core Rules

## Understand First

- Understand the requested outcome before acting.
- Inspect repository evidence instead of guessing.
- Resolve minor ambiguity from existing conventions.
- Ask only when ambiguity materially affects behavior, architecture, data, security, or user-visible results.

## Keep It Simple

- Prefer the smallest safe change that fully solves the task.
- Avoid speculative features, premature abstractions, unnecessary layers, dependencies, and configuration.
- Prefer standard tools and existing project utilities.

## Change Surgically

- Change only what the task requires.
- Do not refactor, rename, move, delete, or reformat unrelated code.
- Preserve existing behavior unless the task explicitly changes it.
- Prefer root-cause fixes over symptom patches.

## Keep Structure Cohesive

- Give each file and module one primary responsibility.
- Keep feature-specific code with its feature.
- Avoid generic dumping grounds such as `utils`, `helpers`, or `common`.
- Keep dependency direction and state ownership explicit.
- Avoid circular dependencies, hidden global state, deep nesting, god modules, and needless tiny files.
- Treat file size as a cohesion signal; split by responsibility, not arbitrary line count.

## Protect Existing Work

- Assume developers and agents may be working concurrently.
- Never revert or overwrite unrelated work.
- Never perform unrelated cleanup.
- Write agents work only in their assigned isolated worktree.
- Only one write agent may write to a worktree.

## Verify Honestly

- Run the smallest relevant validation.
- Never claim a test, build, lint, or check passed unless it ran successfully.
- State what remains unverified and why.
