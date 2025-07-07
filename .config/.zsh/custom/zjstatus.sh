function zjnotify() {
  # Send a notification to zellij status bar
  local message="$1"
  zellij pipe "zjstatus::notify::$message"
}

# # run a command and notify when finished via zellij status bar (zjstatus)
# znotify() {
#   start_time=$(date +%s)
#   local command_preview="${1:0:25}"
#   time "$@"
#   local exit_status=$?
#   end_time=$(date +%s)
#   execution_time=$((end_time - start_time))
#   zjnotify "status: $exit_status, time: ${execution_time}s, command: ${command_preview}"
# }

# --------- Display notification in zjstatus after long running command is finished
LONG_COMMAND_THRESHOLD=3.0 # seconds

# Store command and start time
function zjnotify_preexec() {
  CMD_START_TIME=$EPOCHREALTIME
  CMD_CONTENT=$1
}

# After command runs, calculate duration
function zjnotify_precmd() {
  # Skip if no command was run
  [[ -z "$CMD_CONTENT" || -z "$CMD_START_TIME" ]] && return

  local end_time=$EPOCHREALTIME
  local duration=$((end_time - CMD_START_TIME))

  if ((duration >= LONG_COMMAND_THRESHOLD)); then
    zjnotify "finished in $(printf "%.1f" $duration | tr ',' '.')s: ${CMD_CONTENT:0:50}"
  fi

  # Clear variables for next command
  unset CMD_START_TIME
  unset CMD_CONTENT
}

autoload -Uz add-zsh-hook
add-zsh-hook preexec zjnotify_preexec
add-zsh-hook precmd zjnotify_precmd
# ---------
