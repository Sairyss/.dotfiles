# Source this from your shell config (bash or zsh) to put the herdr-task-runner plugin's commands on PATH:
#   source ~/.config/herdr/local-plugins/herdr-task-runner/shell.sh
# so `herdr-run` and `herdr-run-hold` work by name, in key bindings' shells, television actions
# and in the line `herdr-run --keep/--linger` types into a pane (which is then short: `herdr-run-hold ...`).
# The herdr server (and so key bindings and popups) inherits the PATH of the shell that started it:
# restart the server (herdr server stop) after adding this the first time.
if [ -n "${ZSH_VERSION:-}" ]; then _task_runner_dir="${${(%):-%x}:A:h}"; else _task_runner_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; fi
case ":$PATH:" in
  *":$_task_runner_dir/bin:"*) ;;
  *) export PATH="$_task_runner_dir/bin:$PATH" ;;
esac
# inside a herdr pane, zsh also shows the commands you type in the sidebar (see hooks.zsh)
if [ -n "${ZSH_VERSION:-}" ] && [ "${HERDR_ENV:-}" = 1 ]; then . "$_task_runner_dir/hooks.zsh"; fi
export HERDR_RUN_HOLD="$_task_runner_dir/bin/herdr-run-hold" # the short form herdr-run types when PATH lacks it
unset _task_runner_dir
