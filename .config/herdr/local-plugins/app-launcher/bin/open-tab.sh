#!/usr/bin/env bash
# Usage: open-tab.sh <entrypoint> <command>
# Run <command> in the current pane if its shell is idle, else open <entrypoint> in a new tab.
set -euo pipefail

entrypoint="$1"
command="$2"

herdr="${HERDR_BIN_PATH:-herdr}"
dir="$(bash "$HERDR_PLUGIN_ROOT/bin/resolve-dir.sh")"

pane="$(node -e '
  try { process.stdout.write(JSON.parse(process.env.HERDR_PLUGIN_CONTEXT_JSON).focused_pane_id || "") } catch {}
')"
pane="${pane:-${HERDR_PANE_ID:-}}"

# idle = the shell itself is the foreground process group
idle="$(node -e '
  try {
    const p = JSON.parse(process.argv[1]).result.process_info;
    process.stdout.write(p.foreground_process_group_id === p.shell_pid ? "1" : "");
  } catch {}
' "$([[ -n $pane ]] && "$herdr" pane process-info --pane "$pane" 2>/dev/null || true)")"

if [[ -n $idle ]]; then
  exec "$herdr" pane run "$pane" "$command $(printf '%q' "$dir")"
fi

out="$("$herdr" plugin pane open --plugin app-launcher --entrypoint "$entrypoint" --placement tab --focus --cwd "$dir")"
tab="$(node -e 'process.stdout.write(JSON.parse(process.argv[1]).result.plugin_pane.pane.tab_id)' "$out")"
exec "$herdr" tab focus "$tab"
