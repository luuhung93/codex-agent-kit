# Agent Instructions

Shared rules are in `.agents/rules/`.

Roles:

- explorer → `CORE.md` + `EXPLORE.md`
- planner → `CORE.md` + `PLAN.md`
- worker → `CORE.md` + `IMPLEMENT.md`
- heavy_worker → `CORE.md` + `IMPLEMENT.md`
- reviewer → `CORE.md` + `REVIEW.md`

Core policy:

- Prefer the smallest safe change.
- Read-only roles never modify files.
- Write roles must use isolated Git worktrees.
- Only one write agent may write to a worktree.
- Never revert unrelated work.
- Review changes before applying them to the main workspace.
- Treat native AI sessions as disposable; continue work through Git, worktrees, rules, and run artifacts.
