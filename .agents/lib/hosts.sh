pretty_stream() {
  if ! command -v jq >/dev/null 2>&1; then
    cat
    return
  fi
  jq -Rr --unbuffered '
    (fromjson?) as $e |
    if $e == null then .
    elif $e.type == "item.started" and $e.item.type == "command_execution" then "RUN  " + $e.item.command
    elif $e.type == "item.completed" and $e.item.type == "command_execution" then "EXIT " + (($e.item.exit_code // "?")|tostring) + "  " + $e.item.command
    elif $e.type == "item.completed" and $e.item.type == "agent_message" then $e.item.text
    elif $e.type == "item.completed" and $e.item.type == "error" then "ERROR  " + $e.item.message
    elif $e.type == "assistant" then ($e.message.content[]? | if .type == "text" then .text elif .type == "tool_use" then "TOOL " + .name + " " + (.input|tostring) else empty end)
    elif $e.type == "result" then ($e.result // ($e|tostring))
    elif $e.type == "tool_use" then "TOOL " + ($e.name // "unknown") + " " + (($e.input // {})|tostring)
    elif $e.type == "text" then ($e.text // ($e|tostring))
    else empty end
  '
}

extract_final() {
  local events=$1 final=$2
  [[ -s $final ]] && return
  if command -v jq >/dev/null 2>&1; then
    jq -Rr '
      (fromjson?) as $e |
      if $e == null then empty
      elif $e.type == "item.completed" and $e.item.type == "agent_message" then $e.item.text
      elif $e.type == "result" then ($e.result // empty)
      elif $e.type == "assistant" then ($e.message.content[]? | select(.type == "text") | .text)
      elif $e.type == "text" then ($e.text // empty)
      else empty end
    ' "$events" | tail -n 80 >"$final"
  else
    tail -n 80 "$events" >"$final"
  fi
}

run_host() {
  local host=$1 role=$2 model=$3 sandbox=$4 cwd=$5 prompt=$6 run_dir=$7
  local events="$run_dir/events.jsonl" stderr="$run_dir/stderr.log" final="$run_dir/final.md"
  local status=0 permission_mode opencode_agent

  require_command "$host"
  : >"$events"
  : >"$stderr"
  : >"$final"
  printf '{"type":"engine","event":"start","host":"%s","role":"%s","model":"%s","sandbox":"%s"}\n' \
    "$host" "$role" "$model" "$sandbox" >>"$events"

  set +e
  case $host in
    codex)
      codex exec --ephemeral --json -C "$cwd" -m "$model" -s "$sandbox" -o "$final" "$prompt" \
        > >(tee -a "$events" | pretty_stream) \
        2> >(tee -a "$stderr" >&2)
      status=$?
      ;;
    claude)
      [[ $sandbox == read-only ]] && permission_mode=plan || permission_mode=acceptEdits
      (
        cd "$cwd"
        claude -p --no-session-persistence --verbose --output-format stream-json \
          --permission-mode "$permission_mode" --model "$model" "$prompt"
      ) > >(tee -a "$events" | pretty_stream) \
        2> >(tee -a "$stderr" >&2)
      status=$?
      ;;
    agy)
      [[ $sandbox == read-only ]] && permission_mode=plan || permission_mode=accept-edits
      (
        cd "$cwd"
        agy -p --sandbox --output-format stream-json --mode "$permission_mode" \
          --model "$model" "$prompt"
      ) > >(tee -a "$events" | pretty_stream) \
        2> >(tee -a "$stderr" >&2)
      status=$?
      ;;
    opencode)
      [[ $sandbox == read-only ]] && opencode_agent=plan || opencode_agent=build
      opencode run --format json --dir "$cwd" --agent "$opencode_agent" \
        -m "$model" "$prompt" \
        > >(tee -a "$events" | pretty_stream) \
        2> >(tee -a "$stderr" >&2)
      status=$?
      ;;
    *)
      set -e
      die "unsupported AGENT_HOST: $host"
      ;;
  esac
  set -e

  printf '{"type":"engine","event":"finish","exit_code":%s}\n' "$status" >>"$events"
  extract_final "$events" "$final"
  return "$status"
}
