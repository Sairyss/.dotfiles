#!/usr/bin/env bash
set -euo pipefail

if [ -n "${1:-}" ]; then
  printf '%s\n' "$1"
  exit 0
fi
if [ -n "${HERDR_EXPLORER_DIR:-}" ]; then
  printf '%s\n' "$HERDR_EXPLORER_DIR"
  exit 0
fi
if [ -n "${HERDR_PLUGIN_CONTEXT_JSON:-}" ]; then
  DIR="$(node -e '
    try {
      const ctx = JSON.parse(process.env.HERDR_PLUGIN_CONTEXT_JSON);
      const dir = ctx.focused_pane_cwd || ctx.workspace_cwd;
      if (typeof dir === "string" && dir) process.stdout.write(dir);
    } catch {}
  ')"
  if [ -n "$DIR" ]; then
    printf '%s\n' "$DIR"
    exit 0
  fi
fi
pwd
