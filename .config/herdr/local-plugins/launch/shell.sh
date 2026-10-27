# Source this from your shell config (bash or zsh) to put the launch plugin's commands on PATH:
#   source ~/.config/herdr/local-plugins/launch/shell.sh
# so `herdr-run`, `herdr-run-hold` and `herdr-run-linger` work by name, in key bindings' shells, television actions
# and in the line `herdr-run --keep/--linger` types into a pane (which is then short: `herdr-run-hold ...`).
# The herdr server (and so key bindings and popups) inherits the PATH of the shell that started it:
# restart the server (herdr server stop) after adding this the first time.
if [ -n "${ZSH_VERSION:-}" ]; then _launch_dir="${${(%):-%x}:A:h}"; else _launch_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; fi
case ":$PATH:" in
  *":$_launch_dir/bin:"*) ;;
  *) export PATH="$_launch_dir/bin:$PATH" ;;
esac
unset _launch_dir
