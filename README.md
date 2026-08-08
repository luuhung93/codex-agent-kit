# Codex Agent Kit

Reusable Codex multi-agent configuration for 9Router combo models.

## Agents

| Agent | 9Router combo | Model | Reasoning | Write access | Usage |
| --- | --- | --- | --- | --- | --- |
| `explorer` | `ag_explorer` | Terra | medium | No | Reads repositories well with balanced cost and quality |
| `planner` | `ag_planner` | Terra | high | No | Planning benefits from stronger reasoning than Luna |
| `worker` | `ag_worker` | Luna | high | Yes | Very cost-effective for most implementation tasks |
| `reviewer` | `ag_reviewer` | Luna | high | No | Economical for routine independent reviews |
| `heavy_worker` | `ag_heavy_worker` | Sol | high | Yes | Difficult bugs, architecture, and security work |

Each agent uses its own 9Router combo. No agent shares another role's combo model.

Escalate high-risk reviews to Sol with high reasoning only when the change involves security, authentication, payments, migrations, concurrency, data integrity, architecture, or broad cross-module behavior.

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
