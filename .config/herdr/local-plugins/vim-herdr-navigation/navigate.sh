#!/usr/bin/env bash
#
# vim-herdr-navigation — herdr side
#
# Invoked by a herdr keybind as: navigate.sh <left|down|up|right>
#
# If the focused pane is running Vim/Neovim in the foreground, hand the matching
# Alt chord to that pane so Vim moves between its own splits (and, at a split
# edge, calls back into herdr to cross the pane boundary — see editor/*). The same
# forwarding can be turned on for other TUIs that own Alt+h/j/k/l themselves via
# HERDR_NAV_PASSTHROUGH_RE (off by default — see below). For any other foreground
# process, move herdr's pane focus directly.
#
# Requires `jq`. Without it, detection is skipped and every key just moves the
# herdr pane focus (no Vim awareness).

set -euo pipefail

dir="${1:?usage: navigate.sh <left|down|up|right>}"
herdr="${HERDR_BIN_PATH:-herdr}"
# After `herdr update` replaces the binary under a still-running server, the
# server-injected HERDR_BIN_PATH points at the deleted inode (reported as
# ".../herdr (deleted)"), so every exec would fail with 127. Fall back to PATH.
if ! [ -x "$herdr" ]; then
  herdr="$(command -v herdr || true)"
fi
if [ -z "$herdr" ]; then
  echo "navigate.sh: no usable herdr binary (HERDR_BIN_PATH stale and herdr not on PATH)" >&2
  exit 127
fi
pane="${HERDR_PANE_ID:-}"

case "$dir" in
  left)  key="alt+h" ;;
  down)  key="alt+j" ;;
  up)    key="alt+k" ;;
  right) key="alt+l" ;;
  *) echo "navigate.sh: unknown direction: $dir" >&2; exit 2 ;;
esac

# Foreground process names that mean "Vim is in control of this pane".
# Same matcher vim-tmux-navigator uses: vi, vim, nvim, view, gvim, *diff, ...
vim_re='^g?(view|l?n?vim?x?)(diff)?$'

# Opt-in passthrough for non-Vim TUIs (see README): HERDR_NAV_PASSTHROUGH_RE is an
# ERE matched against the lower-cased process name. Empty (default) forwards only Vim.
passthrough_re="${HERDR_NAV_PASSTHROUGH_RE:-}"

# The herdr-nvim sidebar (`nvim --remote-ui` client of a daemon running our nvim config) is
# treated like any other nvim pane: keys are forwarded to the daemon, whose HERDR_PANE_ID is
# the sidebar pane, so plugins/herdr/navigation.lua hands off from the right pane at a split edge.
forward=0
# HERDR_NAV_NO_FORWARD=1 (set by the nvim mapping when it hit a split edge) skips the
# Vim hand-off so we go straight to herdr movement and cannot bounce back into Vim.
if [ "${HERDR_NAV_NO_FORWARD:-0}" != "1" ] && [ -n "$pane" ] && command -v jq >/dev/null 2>&1; then
  if "$herdr" pane process-info --pane "$pane" 2>/dev/null \
    | jq -e --arg vim "$vim_re" --arg pass "$passthrough_re" \
        '.result.process_info.foreground_processes[]?
         | .name
         | ascii_downcase
         | select(test($vim) or ($pass != "" and (try test($pass) catch false)))' >/dev/null 2>&1; then
    forward=1
  fi
fi

# Move herdr focus. At the left/right edge of the tab, go to the previous/next tab
# instead, wrapping around. Needs jq; without it this is a plain pane focus.
move_herdr() {
  if [ -n "$pane" ] && command -v jq >/dev/null 2>&1; then
    neighbor="$("$herdr" pane neighbor --pane "$pane" --direction "$dir" 2>/dev/null \
      | jq -r '.result.neighbor.neighbor_pane_id // empty' 2>/dev/null || true)"
    if [ -z "$neighbor" ] && { [ "$dir" = left ] || [ "$dir" = right ]; }; then
      ids="$("$herdr" pane get "$pane" 2>/dev/null \
        | jq -r '.result.pane | "\(.workspace_id) \(.tab_id)"' 2>/dev/null || true)"
      ws="${ids% *}"
      tab="${ids#* }"
      if [ -n "$ws" ] && [ -n "$tab" ]; then
        offset=1
        [ "$dir" = left ] && offset=-1
        target="$("$herdr" tab list --workspace "$ws" 2>/dev/null \
          | jq -r --arg cur "$tab" --argjson off "$offset" \
              '.result.tabs | map(.tab_id) | length as $n | (index($cur)) as $i | if $i == null or $n < 2 then empty else .[($i + $off + $n) % $n] end' 2>/dev/null || true)"
        if [ -n "$target" ]; then
          exec "$herdr" tab focus "$target"
        fi
        exit 0 # only one tab
      fi
    fi
  fi
  if [ -n "$pane" ]; then
    exec "$herdr" pane focus --direction "$dir" --pane "$pane"
  else
    # Invoked outside a pane (no $HERDR_PANE_ID): fall back to global focus.
    exec "$herdr" pane focus --direction "$dir" --current
  fi
}

if [ "$forward" -eq 1 ]; then
  exec "$herdr" pane send-keys "$pane" "$key"
else
  move_herdr
fi
