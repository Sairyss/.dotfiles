#!/usr/bin/env bash
# Usage: goto.sh <n>   Focus the n-th tab of the focused workspace.
set -euo pipefail

n="${1:?usage: goto.sh <n>}"
herdr="${HERDR_BIN_PATH:-herdr}"

ws="$(node -e '
  try {
    const c = JSON.parse(process.env.HERDR_PLUGIN_CONTEXT_JSON);
    process.stdout.write(c.workspace_id || c.focused_workspace_id || "");
  } catch {}
')"
ws="${ws:-${HERDR_WORKSPACE_ID:-}}"
if [[ -z $ws ]]; then
  ws="$("$herdr" pane current | node -e 'process.stdout.write(JSON.parse(require("fs").readFileSync(0)).result.pane.workspace_id)')"
fi

tab="$("$herdr" tab list | node -e '
  const [ws, n] = process.argv.slice(1);
  const t = JSON.parse(require("fs").readFileSync(0)).result.tabs.filter(t => t.workspace_id === ws)[n - 1];
  if (t) process.stdout.write(t.tab_id);
' "$ws" "$n")"

[[ -z $tab ]] && exit 0
exec "$herdr" tab focus "$tab"
