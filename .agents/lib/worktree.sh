collect_changes() {
  local cwd=$1 base=$2 run_dir=$3 include_untracked=${4:-false}
  git -C "$cwd" status --short >"$run_dir/status.txt"
  if [[ $include_untracked == true ]]; then
    git -C "$cwd" add -N --all >/dev/null 2>&1 || true
  fi
  git -C "$cwd" diff --stat "$base" >"$run_dir/diff.stat"
  git -C "$cwd" diff --binary --full-index "$base" >"$run_dir/diff.txt"
  cp "$run_dir/diff.txt" "$run_dir/changes.patch"
  if [[ $include_untracked == true ]]; then
    git -C "$cwd" reset -q HEAD -- . >/dev/null 2>&1 || true
  fi
}

create_worktree() {
  local root=$1 run_id=$2 base=$3 key worktree_root worktree
  key="$(basename "$root")-$(printf '%s' "$root" | cksum | awk '{print $1}')"
  worktree_root="${AGENT_WORKTREE_ROOT:-${TMPDIR:-/tmp}/agent-workflow-kit}/$key"
  worktree="$worktree_root/$run_id"
  mkdir -p "$worktree_root"
  git -C "$root" worktree add --detach "$worktree" "$base" >/dev/null
  printf '%s\n' "$worktree"
}

show_diff() {
  local run_dir
  run_dir="$(resolve_run_dir "$1")"
  printf '%s\n' '--- status ---'
  cat "$run_dir/status.txt"
  printf '%s\n' '--- diff stat ---'
  cat "$run_dir/diff.stat"
  printf '%s\n' '--- diff ---'
  cat "$run_dir/diff.txt"
}

apply_run() {
  local root run_dir meta role patch
  root="$(project_root)"
  run_dir="$(resolve_run_dir "$1")"
  meta="$run_dir/run.meta"
  [[ -f $meta ]] || die "missing run metadata: $1"
  role="$(meta_get "$meta" role)"
  role_is_write "$role" || die "only write-agent runs can be applied"
  patch="$run_dir/changes.patch"
  [[ -s $patch ]] || die "run has no changes to apply: $1"
  git -C "$root" apply --check --binary "$patch"
  git -C "$root" apply --binary "$patch"
  date -u '+%Y-%m-%dT%H:%M:%SZ' >"$run_dir/applied-at.txt"
  printf 'Applied %s after git apply --check succeeded.\n' "$1"
}

clean_run() {
  local root run_dir meta cwd registered=false
  root="$(project_root)"
  run_dir="$(resolve_run_dir "$1")"
  meta="$run_dir/run.meta"
  [[ -f $meta ]] || die "missing run metadata: $1"
  cwd="$(meta_get "$meta" cwd)"
  [[ $cwd != "$root" ]] || die "run has no isolated worktree to clean"
  [[ ! -d $cwd ]] || cwd="$(cd "$cwd" && pwd -P)"

  while IFS= read -r line; do
    [[ $line == "worktree $cwd" ]] && registered=true
  done < <(git -C "$root" worktree list --porcelain)

  if [[ $registered == true ]]; then
    git -C "$root" worktree remove --force "$cwd"
    git -C "$root" worktree prune
  elif [[ -d $cwd ]]; then
    die "path exists but is not a registered Git worktree: $cwd"
  fi
  date -u '+%Y-%m-%dT%H:%M:%SZ' >"$run_dir/cleaned-at.txt"
  printf 'Cleaned worktree for %s; artifacts were preserved.\n' "$1"
}
