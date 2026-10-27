# Source this file (it defines a function, it doesn't run anything):
#   source "${TELEVISION_CONFIG:-${XDG_CONFIG_HOME:-$HOME/.config}/television}/scripts/lib/herdr-run.sh"
#
# herdr_run_bin
#   Prints the path of herdr-run: $HERDR_RUN if set, else the one on PATH, else the launch plugin's
#   copy under the herdr config directory ($XDG_CONFIG_HOME/herdr) (a popup or key binding may not have it on PATH).
herdr_run_bin() {
  if [[ -n ${HERDR_RUN:-} ]]; then printf '%s\n' "$HERDR_RUN"; return; fi
  command -v herdr-run 2>/dev/null ||
    printf '%s\n' "${XDG_CONFIG_HOME:-$HOME/.config}/herdr/local-plugins/launch/bin/herdr-run"
}
