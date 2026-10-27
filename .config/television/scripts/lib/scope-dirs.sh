# Source this file (it defines a function, it doesn't run anything):
#   source "$(dirname "$(readlink -f "$0")")/lib/scope-dirs.sh"
#
# scope_dirs PREDICATE [LIMIT]
#   Prints the directories a channel should work on, one per line:
#   1. the current directory, else the git root, if PREDICATE accepts it (and only that one);
#   2. otherwise the LIMIT (default 10) most frecent zoxide directories PREDICATE accepts, best first.
#   PREDICATE is a command or function called with a directory, returning 0 if it is relevant,
#   e.g. "has a package.json". It should only answer yes/no (it may run in a subshell, so anything
#   it sets is lost). Prints nothing, and succeeds, if no directory qualifies.
scope_dirs() {
  local pred=$1 limit=${2:-10} dir
  for dir in "$PWD" "$(git rev-parse --show-toplevel 2>/dev/null || true)"; do
    if [[ -n $dir ]] && "$pred" "$dir"; then printf '%s\n' "$dir"; return 0; fi
  done
  command -v zoxide >/dev/null 2>&1 || return 0
  { zoxide query --list 2>/dev/null || true; } | head -n "$limit" | while IFS= read -r dir; do
    if [[ -d $dir ]] && "$pred" "$dir"; then printf '%s\n' "$dir"; fi
  done || true
}
