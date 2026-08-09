require_command() {
  command -v "$1" >/dev/null 2>&1 || die "required command not found: $1"
}

project_root() {
  git -C "$AGENTS_DIR/.." rev-parse --show-toplevel 2>/dev/null ||
    die "install the kit inside a Git repository"
}

ensure_runs_ignored() {
  local root=$1 exclude pattern='/.agents/runs/*' keep='!/.agents/runs/.gitkeep'
  exclude="$(git -C "$root" rev-parse --git-path info/exclude)"
  [[ $exclude == /* ]] || exclude="$root/$exclude"
  mkdir -p "$RUNS_DIR"
  mkdir -p "$(dirname "$exclude")"
  touch "$exclude"
  grep -Fqx "$pattern" "$exclude" || printf '%s\n' "$pattern" >>"$exclude"
  grep -Fqx "$keep" "$exclude" || printf '%s\n' "$keep" >>"$exclude"
}

safe_run_id() {
  case ${1:-} in
    ''|*[!A-Za-z0-9._-]*) die "invalid run id: ${1:-<empty>}" ;;
  esac
}

resolve_run_dir() {
  safe_run_id "$1"
  local dir="$RUNS_DIR/$1"
  [[ -d $dir ]] || die "run not found: $1"
  printf '%s\n' "$dir"
}

meta_get() {
  local file=$1 key=$2
  awk -F '\t' -v wanted="$key" '$1 == wanted { sub(/^[^\t]*\t/, ""); print; exit }' "$file"
}

role_model() {
  case $1 in
    explorer|planner) printf '%s\n' '9r-terra' ;;
    worker) printf '%s\n' '9r-luna' ;;
    heavy_worker) printf '%s\n' '9r-sol' ;;
    reviewer) printf '%s\n' '9r-terra' ;;
    *) die "unknown role: $1" ;;
  esac
}

role_rule() {
  case $1 in
    explorer) printf '%s\n' 'EXPLORE.md' ;;
    planner) printf '%s\n' 'PLAN.md' ;;
    worker|heavy_worker) printf '%s\n' 'IMPLEMENT.md' ;;
    reviewer) printf '%s\n' 'REVIEW.md' ;;
    *) die "unknown role: $1" ;;
  esac
}

role_sandbox() {
  case $1 in
    explorer|planner|reviewer) printf '%s\n' 'read-only' ;;
    worker|heavy_worker) printf '%s\n' 'workspace-write' ;;
    *) die "unknown role: $1" ;;
  esac
}

host_model() {
  local host=$1 model=$2
  if [[ $host == opencode && $model != */* ]]; then
    printf '%s/%s\n' "${OPENCODE_9ROUTER_PROVIDER:-9router}" "$model"
  else
    printf '%s\n' "$model"
  fi
}

role_is_write() {
  [[ $1 == worker || $1 == heavy_worker || $1 == followup ]]
}

new_run_id() {
  local role=$1 id
  id="$(date '+%Y%m%d-%H%M%S')-$role"
  [[ ! -e $RUNS_DIR/$id ]] || id="$id-$$"
  printf '%s\n' "$id"
}

write_meta() {
  local file=$1 role=$2 host=$3 model=$4 sandbox=$5 cwd=$6 base=$7 target=${8:-} origin=${9:-$2}
  {
    printf 'role\t%s\n' "$role"
    printf 'host\t%s\n' "$host"
    printf 'model\t%s\n' "$model"
    printf 'sandbox\t%s\n' "$sandbox"
    printf 'cwd\t%s\n' "$cwd"
    printf 'base_commit\t%s\n' "$base"
    printf 'target_run\t%s\n' "$target"
    printf 'origin_role\t%s\n' "$origin"
  } >"$file"
}

build_prompt() {
  local role=$1 task=$2 rule_file=$3 target_diff=${4:-}
  cat <<EOF
You are the $role role in a portable, audited agent workflow.

Read and follow these rules:

--- CORE.md ---
$(cat "$AGENTS_DIR/rules/CORE.md")

--- $rule_file ---
$(cat "$AGENTS_DIR/rules/$rule_file")

Task:
$task

Execution contract:
- Work only inside the current repository or isolated worktree.
- Never revert, overwrite, delete, rename, or format unrelated work.
- Before acting, state the files or areas you will inspect or change.
- Report commands and validations truthfully.
- End with a concise list of files inspected or changed, checks run, and remaining risks.
${target_diff:+- Review target diff artifact: $target_diff}
EOF
}

run_role() {
  local role=$1 task=$2 root host model sandbox rule run_id run_dir cwd base prompt status=0
  root="$(project_root)"
  ensure_runs_ignored "$root"
  host="${AGENT_HOST:-codex}"
  model="$(host_model "$host" "$(role_model "$role")")"
  sandbox="$(role_sandbox "$role")"
  rule="$(role_rule "$role")"
  run_id="$(new_run_id "$role")"
  run_dir="$RUNS_DIR/$run_id"
  base="$(git -C "$root" rev-parse HEAD)"
  cwd=$root
  mkdir -p "$run_dir"
  : >"$run_dir/review.md"

  if role_is_write "$role"; then
    cwd="$(create_worktree "$root" "$run_id" "$base")"
  fi

  write_meta "$run_dir/run.meta" "$role" "$host" "$model" "$sandbox" "$cwd" "$base" '' "$role"
  prompt="$(build_prompt "$role" "$task" "$rule")"

  printf 'RUN_ID=%s\nHOST=%s\nMODEL=%s\nCWD=%s\n' "$run_id" "$host" "$model" "$cwd"
  run_host "$host" "$role" "$model" "$sandbox" "$cwd" "$prompt" "$run_dir" || status=$?
  if role_is_write "$role"; then
    collect_changes "$cwd" "$base" "$run_dir" true
  else
    collect_changes "$cwd" "$base" "$run_dir" false
  fi

  printf '\nRun artifacts: %s\n' "$run_dir"
  if role_is_write "$role"; then
    printf 'Review: .agents/agent diff %s\nApply:  .agents/agent apply %s\n' "$run_id" "$run_id"
  fi
  return "$status"
}

run_reviewer() {
  local target_id=$1 target_dir meta target_role origin_role cwd base host model sandbox rule run_id run_dir prompt status=0
  target_dir="$(resolve_run_dir "$target_id")"
  meta="$target_dir/run.meta"
  [[ -f $meta ]] || die "missing run metadata: $target_id"
  target_role="$(meta_get "$meta" role)"
  origin_role="$(meta_get "$meta" origin_role)"
  [[ -n $origin_role ]] || origin_role=$target_role
  cwd="$(meta_get "$meta" cwd)"
  base="$(meta_get "$meta" base_commit)"
  [[ -d $cwd ]] || die "target worktree no longer exists: $cwd"
  role_is_write "$target_role" || die "reviewer requires a write-agent run"

  host="${AGENT_HOST:-$(meta_get "$meta" host)}"
  model="${AGENT_REVIEW_MODEL:-$(role_model reviewer)}"
  [[ $origin_role == heavy_worker && -z ${AGENT_REVIEW_MODEL:-} ]] && model=9r-sol
  model="$(host_model "$host" "$model")"
  sandbox=read-only
  rule="$(role_rule reviewer)"
  run_id="$(new_run_id reviewer)"
  run_dir="$RUNS_DIR/$run_id"
  mkdir -p "$run_dir"
  : >"$run_dir/review.md"
  write_meta "$run_dir/run.meta" reviewer "$host" "$model" "$sandbox" "$cwd" "$base" "$target_id" "$origin_role"
  prompt="$(build_prompt reviewer "Review run $target_id independently. Inspect the worktree and its full diff from base commit $base. Do not modify files." "$rule" "$target_dir/diff.txt")"

  printf 'RUN_ID=%s\nTARGET=%s\nHOST=%s\nMODEL=%s\nCWD=%s\n' "$run_id" "$target_id" "$host" "$model" "$cwd"
  run_host "$host" reviewer "$model" "$sandbox" "$cwd" "$prompt" "$run_dir" || status=$?
  collect_changes "$cwd" "$base" "$run_dir" false
  if [[ $status == 0 && -s $run_dir/final.md ]]; then
    cp "$run_dir/final.md" "$target_dir/review.md"
  fi
  printf '\nReview artifacts: %s\n' "$run_dir"
  return "$status"
}

run_followup() {
  local target_id=$1 task=$2 target_dir meta target_role origin_role cwd base host model run_id run_dir context prompt status=0
  target_dir="$(resolve_run_dir "$target_id")"
  meta="$target_dir/run.meta"
  [[ -f $meta ]] || die "missing run metadata: $target_id"
  target_role="$(meta_get "$meta" role)"
  role_is_write "$target_role" || die "followup requires a write-agent run"
  origin_role="$(meta_get "$meta" origin_role)"
  [[ -n $origin_role ]] || origin_role=$target_role
  cwd="$(meta_get "$meta" cwd)"
  base="$(meta_get "$meta" base_commit)"
  [[ -d $cwd ]] || die "target worktree no longer exists: $cwd"
  touch "$target_dir/review.md"
  collect_changes "$cwd" "$base" "$target_dir" true

  host="${AGENT_HOST:-$(meta_get "$meta" host)}"
  model="$(host_model "$host" "$(role_model "$origin_role")")"
  run_id="$(new_run_id followup)"
  run_dir="$RUNS_DIR/$run_id"
  mkdir -p "$run_dir"
  : >"$run_dir/review.md"
  write_meta "$run_dir/run.meta" followup "$host" "$model" workspace-write "$cwd" "$base" "$target_id" "$origin_role"
  context="Follow up run $target_id in the same isolated worktree using a new AI session.

Previous final report:
$(cat "$target_dir/final.md")

Review findings:
$(cat "$target_dir/review.md")

Current changes are the worktree diff from base commit $base. Inspect them with Git before editing.

Follow-up task:
$task"
  prompt="$(build_prompt "$origin_role followup" "$context" IMPLEMENT.md "$target_dir/diff.txt")"

  printf 'RUN_ID=%s\nTARGET=%s\nHOST=%s\nMODEL=%s\nCWD=%s\n' "$run_id" "$target_id" "$host" "$model" "$cwd"
  run_host "$host" followup "$model" workspace-write "$cwd" "$prompt" "$run_dir" || status=$?
  collect_changes "$cwd" "$base" "$run_dir" true
  printf '\nFollow-up artifacts: %s\nReview: .agents/agent reviewer %s\nApply:  .agents/agent apply %s\n' "$run_dir" "$run_id" "$run_id"
  return "$status"
}
