#!/usr/bin/env bash
# Usage: launch-hold.sh [--linger DURATION] LABEL START_EPOCH EXIT_CODE [COMMAND...]
# (COMMAND defaults to the `cmd` pane token launch.sh set when the command started.)
# Called by launch.sh when a --keep/--linger command has finished. Two jobs:
#
# 1. Sidebar entry, for a pane you are not looking at. A command that succeeded and ran at least
#    HERDR_OMZ_THRESHOLD seconds (default 10, like herdr-ohmyzsh) is marked done. A command that failed
#    (non-zero exit, however long it ran) is marked blocked, herdr's "needs attention" state, labelled
#    "failed (exit N)", with a `result` token "✗ exit N" for sidebar rules. Either stays until the pane
#    is focused, like herdr does for agents; with --linger the wait also ends when the linger is over.
#    herdr drops a reported entry as soon as the pane's foreground process is the plain shell again
#    (that is why it used to vanish when the command finished). It keeps it while a process named like
#    the entry is in the foreground, so this waits as a process with that name.
#
# 2. With --linger: the countdown (launch-linger.sh) to DURATION after the command finished, whether or
#    not the pane was focused. Exit status: 0 = close the pane, 1 = you pressed the keep key.
#    Without --linger the exit status is always 0.
set -uo pipefail

linger=
if [[ ${1:-} == --linger ]]; then linger="${2:?duration}"; shift 2; fi
label="${1:?label}" start="${2:?start epoch}" rc="${3:?exit code}"; shift 3
cmd="$*"
herdr="${HERDR_BIN_PATH:-herdr}"
pane="${HERDR_PANE_ID:-}"
if [[ -z $cmd && -n $pane ]]; then
  cmd="$("$herdr" pane get "$pane" 2>/dev/null | grep -o '"cmd":"[^"]*"' | head -n1 | cut -d'"' -f4)" # the token launch.sh set
fi
[[ -n $cmd ]] || cmd="$label"
here="$(dirname "$(readlink -f "$0")")"

# the moment the linger is over, counted from now (the command just finished)
deadline=0
if [[ -n $linger ]]; then
  n="${linger%[smhd]}"
  case ${linger: -1} in
    m) secs=$((n * 60)) ;;
    h) secs=$((n * 3600)) ;;
    d) secs=$((n * 86400)) ;;
    *) secs=$n ;;
  esac
  deadline=$(($(date +%s) + secs))
fi

# launch.sh gave this entry the full command as display name when the command started (herdr shows only
# the short label, "npm"); clear it on every way out so a later job with the same label doesn't inherit it
meta() { "$herdr" pane report-metadata "$pane" --source launch --agent "$label" --applies-to-source ohmyzsh \
  "$@" --seq "$(date +%s%6N)" >/dev/null 2>&1; }
# everything launch.sh/this script put on the entry besides the state itself
clear_meta() { meta --clear-display-agent --clear-state-labels --clear-token result --clear-token cmd; }
focused() { [[ "$("$herdr" pane get "$pane" 2>/dev/null)" == *'"focused":true'* ]]; }
dir=
trap '[[ -z $dir ]] || rm -rf "$dir"; [[ -z $pane ]] || clear_meta' EXIT
trap 'exit 0' INT # Ctrl-C while waiting: close now (exit status 0), like in the countdown

release() { "$herdr" pane release-agent "$pane" --source ohmyzsh --agent "$label" --seq "$(date +%s%6N)" >/dev/null 2>&1; }

hold() {
  [[ -n $pane ]] || return 0
  local took=$(($(date +%s) - start)) state=idle
  if ((rc != 0)); then
    state=blocked # a failure is shown whatever its duration
  elif ((took < ${HERDR_OMZ_THRESHOLD:-10})); then
    release; return 0 # too quick to be worth showing
  fi
  # herdr-ohmyzsh marked the entry working and only clears that when the prompt comes back, which is after
  # this script (the linger countdown), so an entry we don't hold has to be dropped here.
  # herdr itself knows when a finished command was seen, also when it runs inside another terminal that
  # you switched away from (its own focus flag stays true then), so a success is always reported and the
  # wait below ends when herdr stops showing it as done. A failure (blocked) has no seen state: it is only
  # skipped when the pane is focused, which is when you are looking at it.
  if [[ $state == blocked ]] && focused; then release; return 0; fi

  "$herdr" pane report-agent "$pane" --source ohmyzsh --agent "$label" --state "$state" \
    --message "$cmd (exit $rc, took ${took}s)" --seq "$(date +%s%6N)" >/dev/null 2>&1 || return 0
  if [[ $state == blocked ]]; then
    # a metadata call replaces the name set by launch.sh unless it repeats it
    name="$cmd"; ((${#name} > 80)) && name="${name:0:79}…"
    meta --display-agent "$name" --state-label "blocked=failed (exit $rc)" --token "result=✗ exit $rc"
  fi

  # the waiting process is a copy of bash under the entry's name
  dir="$(mktemp -d)" || return 0
  ln -s "$(command -v bash)" "$dir/$label"
  # waits until herdr shows a done entry as seen, or for blocked until the pane is focused, or the linger is over
  cat >"$dir/wait.sh" <<'WAIT'
herdr="$1" pane="$2" deadline="$3" state="$4"
while :; do
  info="$("$herdr" pane get "$pane" 2>/dev/null)"
  if [[ $state == blocked ]]; then
    [[ $info == *'"focused":true'* ]] && break
  else
    [[ $info == *'"agent_status":"done"'* ]] || break
  fi
  ((deadline > 0)) && (($(date +%s) >= deadline)) && break
  sleep 1
done
WAIT
  "$dir/$label" "$dir/wait.sh" "$herdr" "$pane" "$deadline" "$state"
  # the wait is over (focused, or the linger ran out): remove the entry now instead of leaving it to herdr
  release
}

hold
[[ -z $pane ]] || clear_meta # the entry is gone now; don't leave the name or labels behind

if [[ -n $linger ]]; then
  "$here/launch-linger.sh" "@$deadline"
  exit $?
fi
exit 0
