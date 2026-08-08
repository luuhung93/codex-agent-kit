# AI Development Rules

Use only the rules relevant to your role.

All agents must read:

- `.codex/instructions/rules/CORE.md`

Role-specific rules:

- Explorer → `.codex/instructions/rules/EXPLORATION.md`
- Planner → `.codex/instructions/rules/PLANNING.md`
- Worker → `.codex/instructions/rules/IMPLEMENTATION.md`
- Heavy Worker → `.codex/instructions/rules/IMPLEMENTATION.md` and `.codex/instructions/ARCHITECTURE.md` when relevant
- Reviewer → `.codex/instructions/rules/REVIEW.md`

Read `.codex/instructions/ARCHITECTURE.md` only when the task affects architecture, module boundaries, data flow, persistence, security, cross-service behavior, or multiple features.

Do not load unrelated rule files.
