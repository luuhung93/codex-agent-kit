self_test() (
  require_command git
  local temp project fake_bin run_id followup_id worktree host
  temp="$(mktemp -d)"
  trap 'rm -rf "$temp"' EXIT
  project="$temp/project"
  fake_bin="$temp/bin"
  mkdir -p "$project/.agents/lib" "$project/.agents/rules" "$project/.agents/runs" "$fake_bin"
  cp "$SCRIPT_PATH" "$project/.agents/agent"
  cp "$AGENTS_DIR"/lib/*.sh "$project/.agents/lib/"
  cp "$AGENTS_DIR"/rules/*.md "$project/.agents/rules/"
  touch "$project/.agents/runs/.gitkeep"
  cat >"$fake_bin/fake-agent-cli" <<'EOF'
#!/usr/bin/env bash
set -e
cwd=$PWD final= sandbox=read-only prompt=
while (($#)); do
  case $1 in
    -C) cwd=$2; shift 2 ;;
    --dir) cwd=$2; shift 2 ;;
    -o) final=$2; shift 2 ;;
    -s) sandbox=$2; shift 2 ;;
    --permission-mode) [[ $2 == acceptEdits ]] && sandbox=workspace-write; shift 2 ;;
    --mode) [[ $2 == accept-edits ]] && sandbox=workspace-write; shift 2 ;;
    --agent) [[ $2 == build ]] && sandbox=workspace-write; shift 2 ;;
    -m) shift 2 ;;
    --model) shift 2 ;;
    --ephemeral|--json|--sandbox|--no-session-persistence|--verbose|--output-format|-p|exec|run) shift ;;
    *) prompt=$1; shift ;;
  esac
done
if [[ $sandbox == workspace-write ]]; then
  if [[ $prompt == *'Fix the remaining test failure'* ]]; then
    printf 'followup change\n' >"$cwd/followup-change.txt"
  else
    printf 'agent change\n' >"$cwd/agent-change.txt"
  fi
fi
[[ -z $final ]] || printf 'fake final\n' >"$final"
printf '{"type":"result","result":"fake final"}\n'
EOF
  chmod +x "$fake_bin/fake-agent-cli" "$project/.agents/agent"
  for host in codex claude agy opencode; do ln -s fake-agent-cli "$fake_bin/$host"; done
  (
    cd "$project"
    git init -q
    git config user.name 'Agent Self Test'
    git config user.email 'agent@example.invalid'
    printf 'base\n' >base.txt
    git add .
    git commit -qm base
    for host in codex claude agy opencode; do
      PATH="$fake_bin:$PATH" AGENT_HOST="$host" .agents/agent explorer 'inspect only' >/dev/null
    done
    PATH="$fake_bin:$PATH" AGENT_HOST=codex .agents/agent worker 'create agent-change.txt' >/dev/null
    [[ ! -e agent-change.txt ]]
    run_id="$(find .agents/runs -mindepth 1 -maxdepth 1 -type d -name '*-worker*' -exec basename {} \; | head -1)"
    [[ -n $run_id && -s .agents/runs/$run_id/changes.patch ]]
    PATH="$fake_bin:$PATH" AGENT_HOST=codex .agents/agent reviewer "$run_id" >/dev/null
    [[ -s .agents/runs/$run_id/review.md ]]
    PATH="$fake_bin:$PATH" AGENT_HOST=claude .agents/agent followup "$run_id" 'Fix the remaining test failure' >/dev/null
    followup_id="$(find .agents/runs -mindepth 1 -maxdepth 1 -type d -name '*-followup*' -exec basename {} \; | head -1)"
    [[ -n $followup_id && -s .agents/runs/$followup_id/changes.patch ]]
    .agents/agent apply "$followup_id" >/dev/null
    [[ $(cat agent-change.txt) == 'agent change' ]]
    [[ $(cat followup-change.txt) == 'followup change' ]]
    worktree="$(awk -F '\t' '$1 == "cwd" {print $2}' .agents/runs/$followup_id/run.meta)"
    .agents/agent clean "$followup_id" >/dev/null
    [[ ! -d $worktree && -d .agents/runs/$followup_id ]]
  )
  printf 'self-test: ok\n'
)
