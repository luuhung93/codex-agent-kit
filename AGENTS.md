# Codex Repository Instructions

Follow `.codex/instructions/RULES.md` for repository-specific engineering rules.

## Agent strategy

Use subagents when they materially improve correctness or reduce context noise.

- `explorer`: repository search, code tracing, dependency discovery
- `planner`: complex implementation planning
- `worker`: normal implementation tasks
- `heavy_worker`: difficult, ambiguous, or high-risk implementation
- `reviewer`: independent final review

For simple tasks, do not over-orchestrate.

For complex tasks, prefer:

`explorer` → `planner` → `worker`/`heavy_worker` → `reviewer`

Run independent exploration tasks in parallel when useful.

Do not have multiple write agents edit the same files concurrently.

Do not revert unrelated changes made by users or other agents.

Prefer the smallest safe change that fully satisfies the request.
