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
#    Whether you are away is read from the terminal's focus events (launch.sh turns them on when it types the
#    command): herdr's own focus flag stays true when herdr runs inside another terminal (an ssh/incus
#    session) and you switch away from that terminal, and herdr's API never reports "done" (its sidebar works
#    that out per client from the same events).
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

# focus events from the terminal, if launch.sh turned them on (ESC [ I = focus in, ESC [ O = focus out)
outer_out=0
have_tty() { { : </dev/tty; } 2>/dev/null; }
drain_events() {
  local c r
  while IFS= read -rsn1 -t 0.05 c </dev/tty 2>/dev/null; do
    [[ $c == $'\e' ]] || continue
    IFS= read -rsn2 -t 0.05 r </dev/tty 2>/dev/null
    case $r in '[O') outer_out=1 ;; '[I') outer_out=0 ;; esac
  done
}
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
  local away=0 by=outer
  have_tty && drain_events
  ((outer_out)) && away=1
  focused || { away=1; by=flag; } # you switched to another tab/workspace of this herdr
  if ((!away)); then release; return 0; fi # you are looking at it

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
  # ends when you are back (a focus-in event, or the pane is focused when you were away inside herdr) or the
  # linger is over
  cat >"$dir/wait.sh" <<'WAIT'
herdr="$1" pane="$2" deadline="$3" by="$4"
tty=0; { : </dev/tty; } 2>/dev/null && tty=1
while :; do
  if [[ $by == flag ]]; then
    [[ "$("$herdr" pane get "$pane" 2>/dev/null)" == *'"focused":true'* ]] && break
    sleep 1
  elif ((tty)); then
    if IFS= read -rsn1 -t 1 c </dev/tty && [[ $c == $'\e' ]]; then
      IFS= read -rsn2 -t 0.05 r </dev/tty
      [[ $r == '[I' ]] && break
    fi
  else
    sleep 1
  fi
  ((deadline > 0)) && (($(date +%s) >= deadline)) && break
done
WAIT
  "$dir/$label" "$dir/wait.sh" "$herdr" "$pane" "$deadline" "$by"
  release
}

hold
if have_tty; then printf '\033[?1004l' >/dev/tty; stty echo </dev/tty 2>/dev/null; fi # focus events off again
[[ -z $pane ]] || clear_meta # the entry is gone now; don't leave the name or labels behind

if [[ -n $linger ]]; then
  "$here/launch-linger.sh" "@$deadline"
  exit $?
fi
exit 0
