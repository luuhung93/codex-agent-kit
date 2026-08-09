# Agent Workflow Kit

A small, portable workflow for running coding agents safely across Codex, Claude, AGY, and OpenCode.

Download the release ZIP, extract it into the root of an existing Git project, and use `.agents/agent`. The kit does not require `.codex/`, `.claude/`, `.opencode/`, adapter directories, or persistent AI sessions.

## What It Provides

- Role-specific rules with minimal context loading.
- Read-only exploration, planning, and review roles.
- Detached Git worktrees for every write role.
- Stateless follow-ups that can switch AI hosts.
- Live JSONL events, final reports, diffs, reviews, and patches.
- A human-controlled `git apply --check` gate.
- No automatic merge into the main workspace.

## Files

```text
AGENTS.md
CLAUDE.md
.agents/
├── agent
├── rules/
│   ├── CORE.md
│   ├── EXPLORE.md
│   ├── PLAN.md
│   ├── IMPLEMENT.md
│   └── REVIEW.md
└── runs/
    └── .gitkeep
```

## Requirements

- Bash
- Git
- One supported CLI: `codex`, `claude`, `agy`, or `opencode`
- 9Router model aliases: `9r-terra`, `9r-luna`, and `9r-sol`
- Optional: `jq` for readable live event output

OpenCode uses `9router/9r-*` by default because it requires `provider/model`. Override the provider name when necessary:

```bash
export OPENCODE_9ROUTER_PROVIDER=my-provider
```

## Install From Release

Download `agent-workflow-kit-v2.0.0.zip` from GitHub Releases and extract its contents into the root of your project.

```bash
unzip agent-workflow-kit-v2.0.0.zip -d /tmp/agent-workflow-kit
cp -R /tmp/agent-workflow-kit/agent-workflow-kit-v2.0.0/. /path/to/my-project/
cd /path/to/my-project
.agents/agent self-test
```

The extraction command copies dotfiles such as `.agents/`.

## Roles

| Role | Model | Access | Workspace |
| --- | --- | --- | --- |
| `explorer` | `9r-terra` | read-only | main project |
| `planner` | `9r-terra` | read-only | main project |
| `worker` | `9r-luna` | workspace-write | detached worktree |
| `heavy_worker` | `9r-sol` | workspace-write | detached worktree |
| `reviewer` | `9r-terra` | read-only | target worktree |
| high-risk review | `9r-sol` | read-only | target worktree |

Every role reads `CORE.md` plus only its role-specific rule file.

## Choose A Host

Set a default:

```bash
export AGENT_HOST=codex
```

Or select one per command:

```bash
AGENT_HOST=claude .agents/agent worker "Fix authentication"
AGENT_HOST=agy .agents/agent reviewer RUN_ID
AGENT_HOST=opencode .agents/agent explorer "Trace the request flow"
```

Supported values are `codex`, `claude`, `agy`, and `opencode`.

## Workflow

Explore and plan without changing files:

```bash
.agents/agent explorer "Trace the authentication flow"
.agents/agent planner "Plan the smallest safe fix"
```

Implement in an isolated detached worktree:

```bash
.agents/agent worker "Implement the authentication fix"
.agents/agent heavy_worker "Fix the concurrency race"
```

Each command prints a `RUN_ID`. Inspect and review a write run:

```bash
.agents/agent diff RUN_ID
.agents/agent reviewer RUN_ID
```

Continue the same worktree in a fresh AI session, optionally with another host:

```bash
AGENT_HOST=claude .agents/agent followup RUN_ID \
  "Fix the remaining review findings"
```

`followup` does not resume a native AI conversation. It starts a new session with the same worktree, current Git diff, previous final report, and saved review findings.

Apply reviewed changes to the main workspace:

```bash
.agents/agent apply RUN_ID
```

The engine runs:

```bash
git apply --check changes.patch
git apply changes.patch
```

It never merges automatically.

Remove the detached worktree after applying or rejecting the run:

```bash
.agents/agent clean RUN_ID
```

`clean` preserves run artifacts for auditing.

## Run Artifacts

```text
.agents/runs/20260809-111200-worker/
├── final.md
├── events.jsonl
├── stderr.log
├── status.txt
├── diff.stat
├── diff.txt
├── review.md
└── changes.patch
```

Runtime directories are added to the repository-local Git exclude file. `.agents/runs/.gitkeep` remains tracked.

## Stateless By Design

Each invocation starts a new AI session:

- Codex uses `--ephemeral`.
- Claude uses `--no-session-persistence`.
- AGY does not resume a conversation.
- OpenCode does not continue a session.

The source of truth is:

```text
Git + worktree + rules + artifacts
```

Hidden conversation memory is disposable and never required to continue work.

## Safety Model

```text
rules
  → host sandbox or permission mode
  → isolated write worktree
  → JSONL and diff audit
  → independent review
  → human apply gate
```

Only one write agent may write to a worktree. Write agents never modify the main workspace directly.

## Validate The Engine

```bash
.agents/agent self-test
```

The self-test uses fake local host executables. It verifies all four host adapters and the complete worktree → review → cross-host follow-up → patch → apply → clean flow without calling an AI API.
