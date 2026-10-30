# zsh hooks of the herdr-task-runner plugin: show the commands you type in a herdr pane in the sidebar, like an
# agent, once they run longer than a threshold (working while they run, done or failed after), (herdr itself notifies on
# that state change). Sourced by shell.sh, only inside a herdr pane.
#
# A line typed by `herdr-run --keep/--linger` (it contains `herdr-run-hold`) is the same job: these hooks show
# it as working, herdr-run-hold marks it done/failed, so it is not reported twice.
#
# Settings: the [jobs] table of the plugin's config (see config.default.toml). sidebar.py writes it to
# shell.env in the plugin's state dir on every pass and this reads it when the shell starts, so a changed
# setting reaches the shells opened after it. The environment variables below override it (set them before
# this is sourced): HERDR_TASK_RUNNER_THRESHOLD (typed commands), HERDR_TASK_RUNNER_RUN_THRESHOLD (herdr-run),
# HERDR_TASK_RUNNER_REPORT (true/false).
# Needs zsh and the herdr CLI only.

[[ ${HERDR_ENV:-} == 1 && -n ${HERDR_PANE_ID:-} ]] || return 0

zmodload zsh/datetime
autoload -Uz add-zsh-hook

# herdr-run types `herdr-run-hold ...` into the pane: a function, so it works without the plugin's bin/ on PATH
# (HERDR_RUN_HOLD is exported by shell.sh)
herdr-run-hold() {
  # the command is over: the hold shows the linger countdown in the `timer` token instead of the elapsed time
  _tr_kill_running_watcher
  "${HERDR_RUN_HOLD:-${XDG_CONFIG_HOME:-$HOME/.config}/herdr/local-plugins/herdr-task-runner/bin/herdr-run-hold}" "$@"
}

typeset -g _tr_bin="${HERDR_BIN_PATH:-herdr}"
# defaults, for a shell that starts before the plugin has written shell.env
typeset -g _tr_source=task-runner _tr_terminal_threshold=10 _tr_run_threshold=10
typeset -g _tr_report=true _tr_label_style=program _tr_timer_interval=5
typeset -g _tr_elapsed_timer=true _tr_countdown_timer=true
typeset -g _tr_ignore='nvim vim vi emacs nano less more man ssh mosh tmux screen zellij htop top btop lazygit tig fzf herdr'
typeset -g _tr_ignore_bare='python python3 irb pry node psql mysql sqlite3'
typeset -g _tr_wrappers='sudo doas command builtin exec nohup time nice env caffeinate'
() {
  local f="${HERDR_PLUGIN_STATE_DIR:-${XDG_STATE_HOME:-$HOME/.local/state}/herdr/plugins/herdr-task-runner}/shell.env"
  [[ -r $f ]] && source "$f"
}
[[ -z ${HERDR_TASK_RUNNER_THRESHOLD:-} ]] || _tr_terminal_threshold=$HERDR_TASK_RUNNER_THRESHOLD
[[ -z ${HERDR_TASK_RUNNER_RUN_THRESHOLD:-} ]] || _tr_run_threshold=$HERDR_TASK_RUNNER_RUN_THRESHOLD
[[ -z ${HERDR_TASK_RUNNER_REPORT:-} ]] || _tr_report=$HERDR_TASK_RUNNER_REPORT
typeset -ga _tr_ignore_a _tr_ignore_bare_a _tr_wrappers_a
_tr_ignore_a=(${=_tr_ignore}) _tr_ignore_bare_a=(${=_tr_ignore_bare}) _tr_wrappers_a=(${=_tr_wrappers})

typeset -g  _tr_cmd= _tr_label=
typeset -gF _tr_start=0
typeset -gi _tr_managed=0 _tr_watcher=0 _tr_registered=0 _tr_marked=0

# herdr drops a report whose --seq is not above the last one it saw for this pane and source, and that memory
# outlives the shell: microseconds since the epoch stay monotonic across shells.
_tr_seq() { REPLY=$(( EPOCHREALTIME * 1000000 )); REPLY=${REPLY%.*}; }

# a hook must never break the prompt because the socket went away
_tr_call() { "$_tr_bin" "$@" >/dev/null 2>&1; return 0 }

# REPLY = the program of a command line (without env assignments, wrappers, options); _tr_args = how many
# words follow it. Returns 1 when there is nothing to report.
_tr_program() {
  local -a words; local w i=0
  words=(${(z)1})
  for w in $words; do
    (( i++ ))
    case $w in
      *=*|-*) continue ;;
      *) (( ${_tr_wrappers_a[(Ie)$w]} )) && continue
         REPLY="${w:t}"; _tr_args=$(( ${#words} - i )); return 0 ;;
    esac
  done
  return 1
}

# REPLY = a label herdr accepts: lowercase [a-z0-9_-], at most 32 characters, starting with a letter
# Same steps, same order as label_of in herdr-run, or one command would be filed under two labels.
_tr_sanitize() {
  local l="${(L)1}"
  l="${l//[^a-z0-9_-]/-}"
  l="${(j:-:)${(s:-:)l}}" # squeeze runs of -, trim both ends
  [[ $l == [a-z]* ]] || l=shell
  l="${l[1,32]}"
  REPLY="${l%-}"
}

# REPLY = the label of the entry for a command line. herdr names its own notification after the label, so
# with label_style = command it is the whole command (sanitized, cut at 32 characters): "npm-run-docker-env-reset"
# rather than "npm". Same rule as label_of in herdr-run: herdr-run-hold gets its label from there.
_tr_label_for() {
  local line="${1%%; rc=*}" w
  local -a words
  words=(${=line})
  while (( $#words )); do
    w=$words[1]
    [[ $w == *=* || $w == -* ]] || (( ${_tr_wrappers_a[(Ie)$w]} )) || break
    shift words
  done
  (( $#words )) || { REPLY=shell; return }
  if [[ $_tr_label_style == command ]]; then
    _tr_sanitize "${(j:-:)words}"
  else
    _tr_sanitize "${words[1]:t}"
  fi
}

_tr_human() {
  local -i s=$1
  if (( s < 60 )); then REPLY="${s}s"
  elif (( s < 3600 )); then REPLY="$(( s / 60 ))m $(( s % 60 ))s"
  else REPLY="$(( s / 3600 ))h $(( (s % 3600) / 60 ))m"; fi
}

# _tr_kill_running_watcher: _tr_kill_watcher for the command that is running now (its elapsed time and threshold)
_tr_kill_running_watcher() {
  _tr_kill_watcher $(( EPOCHREALTIME - _tr_start )) $(( _tr_managed ? _tr_run_threshold : _tr_terminal_threshold ))
}

# $1: seconds the command ran, $2: the threshold. With elapsed_timer on the watcher lives as long as the command
# (it keeps the `timer` token up to date), so it is always signalled. Off, it is gone a moment after the threshold;
# its pid may belong to something else by then, so it is only signalled while it can still be running.
_tr_kill_watcher() {
  (( _tr_watcher )) || return 0
  [[ $_tr_elapsed_timer == true ]] || (( ${1:-0} < ${2:-0} + 2 )) || { _tr_watcher=0; return 0; }
  # its own process group under job control; the bare pid when not (non-interactive shells)
  kill -TERM -- -$_tr_watcher 2>/dev/null || kill -TERM $_tr_watcher 2>/dev/null
  _tr_watcher=0
}

# drop the entry of the last command (and what failure put on it)
_tr_release() {
  (( _tr_registered )) || return 0
  local REPLY
  _tr_seq
  if (( _tr_marked )); then
    _tr_call pane report-metadata "$HERDR_PANE_ID" --source $_tr_source --agent "$_tr_label" \
      --clear-display-agent --clear-state-labels --clear-token result --clear-token cmd --clear-token args --clear-token timer --seq $REPLY
    _tr_marked=0
    _tr_seq
  fi
  _tr_call pane release-agent "$HERDR_PANE_ID" --source $_tr_source --agent "$_tr_label" --seq $REPLY
  _tr_registered=0
}

_tr_preexec() {
  # $2 is the line with aliases expanded; $1 the raw one, used when history is off
  local cmd="${2:-$1}" REPLY
  _tr_args=0
  # focus reports (DEC 1004) left on by an interrupted herdr-run-hold type ESC[I/ESC[O into the prompt: every
  # line switches them off, except the ones herdr-run types to need them
  [[ $cmd == *1004h* || $cmd == *herdr-run-hold* ]] || print -n '\e[?1004l'
  _tr_release # the previous command's mark goes once you move on
  _tr_cmd= _tr_start=0 _tr_managed=0 _tr_marked=0
  _tr_program "$cmd" || return 0
  local prog=$REPLY
  (( ${_tr_ignore_a[(Ie)$prog]} )) && return 0
  (( _tr_args == 0 && ${_tr_ignore_bare_a[(Ie)$prog]} )) && return 0 # a REPL, not a job

  [[ $cmd == *herdr-run-hold* ]] && _tr_managed=1
  _tr_label_for "$cmd"
  # without the "; rc=$?; herdr-run-hold ..." herdr-run appends: that is not part of the command
  cmd=${cmd%%; rc=*}
  _tr_label=$REPLY _tr_cmd=$cmd _tr_start=$EPOCHREALTIME
  [[ $_tr_report == true ]] || return 0

  # wait out the threshold in the background, then report "working"; precmd kills it for commands that end
  # sooner, so quick ones never flicker. zselect sleeps without forking.
  local -i cs=$(( (_tr_managed ? _tr_run_threshold : _tr_terminal_threshold) * 100 ))
  _tr_seq
  local seq=$REPLY
  # the name is the whole command, or just the label (the program) with label_style = program; the `cmd`
  # token keeps the whole command either way, sidebar.py derives the `args` token (agent row) from it
  local name="$cmd"
  (( ${#name} > 80 )) && name="${name[1,79]}…"
  [[ $_tr_label_style == command ]] || name=$_tr_label
  local -i shell_pid=$$
  (
    zmodload zsh/zselect 2>/dev/null && (( cs > 0 )) && zselect -t $cs
    "$_tr_bin" pane report-agent "$HERDR_PANE_ID" --source $_tr_source --agent "$_tr_label" \
      --state working --message "$cmd" --seq $seq
    # herdr only takes metadata for an entry it has confirmed (the process named like the label is the
    # foreground one), so sent straight after the report it is dropped and the entry shows the terminal title
    zselect -t 100
    "$_tr_bin" pane report-metadata "$HERDR_PANE_ID" --source $_tr_source --agent "$_tr_label" \
      --display-agent "$name" --token "cmd=${cmd[1,80]}" --seq $(( seq + 1 ))
    # then the time since the command started, in the `timer` token, at every multiple of [jobs] timer_interval
    # seconds (a herdr call per second would be too many). The first one is due now: the threshold, rounded to
    # the second. Off: this ends here, nothing keeps running (no `exit`: that would run the zshexit hook).
    if [[ $_tr_elapsed_timer == true ]]; then
      local -F e
      local -i n w
      local text
      # a shell that dies without running zshexit (SIGKILL) can't stop this loop: it ends with the shell
      while kill -0 $shell_pid 2>/dev/null; do
        e=$(( EPOCHREALTIME - _tr_start ))
        n=$(( e + 0.5 ))
        text="🕐${n}s"
        (( n < 60 )) || text="🕐$(( n / 60 ))m $(printf '%02d' $(( n % 60 )))s"
        (( n < 3600 )) || text="🕐$(( n / 3600 ))h $(printf '%02d' $(( n % 3600 / 60 )))m"
        _tr_seq
        "$_tr_bin" pane report-metadata "$HERDR_PANE_ID" --source $_tr_source --agent "$_tr_label" \
          --display-agent "$name" --token "timer=$text" --seq $REPLY
        # sleep to the next multiple of the interval (not a whole interval: the calls would add up and the values drift), plus a
        # hair so the wake-up lands after it
        e=$(( EPOCHREALTIME - _tr_start ))
        w=$(( ((n / _tr_timer_interval + 1) * _tr_timer_interval - e) * 100 + 3 )) # an integer variable truncates
        (( w > 0 )) || w=1
        zselect -t $w
        (( $? == 1 )) || sleep $_tr_timer_interval # zselect returns 1 when the time is up; anything else (missing module): don't spin
      done
    fi
  ) >/dev/null 2>&1 &!
  _tr_marked=1 # the name is on the entry once it is reported: clear it with the entry
  _tr_watcher=$!
}

_tr_precmd() {
  local -i code=$? # first statement: the status of the command that just ended
  (( _tr_start )) || return 0
  local -F elapsed=$(( EPOCHREALTIME - _tr_start ))
  local cmd=$_tr_cmd label=$_tr_label start=$_tr_start REPLY
  local -i managed=$_tr_managed threshold
  threshold=$(( managed ? _tr_run_threshold : _tr_terminal_threshold ))
  _tr_cmd= _tr_start=0 _tr_managed=0
  _tr_kill_watcher $elapsed $threshold
  (( elapsed >= threshold )) || return 0

  # herdr-run-hold marked it already; just drop what the "working" report left (it may have
  # been interrupted before it ran)
  if (( managed )); then
    _tr_registered=1; _tr_release; return 0
  fi
  # Ctrl-C is a decision, not a result
  if (( code == 130 )); then _tr_registered=1; _tr_release; return 0; fi

  # Mark it done/failed and keep it in the sidebar until you look at the pane, like herdr-run-hold does for
  # herdr-run jobs. herdr drops an entry once the shell is in front again, so the hold runs from here as the
  # foreground process (the prompt waits, but only while you are away from the pane: when you are looking at it
  # the entry is just released). It reads no keys, so what you type ahead is kept.
  if [[ $_tr_report == true ]]; then
    local name="$cmd"
    (( ${#name} > 80 )) && name="${name[1,79]}…"
    _tr_registered=0 # the hold releases the entry itself
    herdr-run-hold --typed ${start%.*} "$label" $code "$cmd" >/dev/null 2>&1 </dev/null
  fi
  return 0
}

_tr_zshexit() { _tr_kill_running_watcher; _tr_release }

add-zsh-hook preexec _tr_preexec
add-zsh-hook precmd  _tr_precmd
add-zsh-hook zshexit _tr_zshexit
