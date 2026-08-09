# Codex Agent Kit

Reusable Codex multi-agent configuration for 9Router combo models.

## Agents

| Agent | Model | Reasoning | Write access | Usage |
| --- | --- | --- | --- | --- |
| `explorer` | `gpt-5.6-sol` | high | No | Repository tracing and discovery |
| `planner` | `gpt-5.6-sol` | high | No | Evidence-based planning |
| `worker` | `gpt-5.6-sol` | high | Yes | Normal implementation tasks |
| `heavy_worker` | `gpt-5.6-sol` | high | Yes | Difficult or high-risk tasks |
| `reviewer` | `gpt-5.6-sol` | high | No | Independent final review |

All agents use the same 9Router combo `gpt-5.6-sol`. Differentiation is by role instructions and sandbox mode, not model.

## Suggested flows

- Simple: `worker` → `reviewer`
- Repository discovery: `explorer` → `worker` → `reviewer`
- Complex or high-risk: `explorer` → `planner` → `heavy_worker` → `reviewer`

Use this repository as a starting template, then document project-specific boundaries in `.codex/instructions/ARCHITECTURE.md` and adjust role rules only when needed.

## Rule loading

`.codex/instructions/RULES.md` routes each agent to a short shared core and one role-specific rule file. Keep project architecture in `.codex/instructions/ARCHITECTURE.md` so agents load it only for changes involving system boundaries, data flow, persistence, security, or multiple modules.

## Verify installation

Run these commands from the target repository root:

```bash
codex doctor --summary
codex --ask-for-approval never "List the active project instructions and custom agents."
```

The second command checks discovery only. For a live custom-agent spawn check, use an orchestrator model that supports custom agent selection:

```bash
codex -m 'cx/gpt-5.5' --ask-for-approval never \
  "Spawn the explorer custom agent and ask it to reply only ROLE_OK explorer."
```

## Use as a project template

Create a new project from the repository template or download a versioned ZIP from GitHub Releases. Preserve the hidden `.codex` directory when extracting or copying files.

You can also ask Codex to prepare a new project from this template:

```text
Download the latest release ZIP from the codex-agent-kit repository.
Extract it into a new empty project directory.
Preserve AGENTS.md and the hidden .codex directory.
Initialize a new Git repository, then run the verification commands from the kit README.
```

Use an approval mode that permits Codex to request network access for the download.
