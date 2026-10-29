#!/usr/bin/env bash
# Install the plugins from .config/herdr/plugins.list.
# Usage: scripts/sync-plugins.sh [ssh-target]   (no target = this machine)
set -euo pipefail

list="$(dirname "$(readlink -f "$0")")/../plugins.list"
target="${1:-}"
dotfiles="${DOTFILES:-$HOME/.dotfiles}" # where the repo is checked out (on the remote too, if it uses the same variable)

h() { if [[ -n $target ]]; then ssh -n "$target" herdr "$@"; else herdr "$@"; fi; }

installed="$(h plugin list)"

while read -r kind src ref; do
  [[ -z $kind || $kind == \#* ]] && continue
  case $kind in
    github)
      if grep -q "github:$src@$ref" <<<"$installed"; then
        echo "ok      $src@${ref:0:7}"
      else
        echo "install $src@${ref:0:7}"
        h plugin install --yes --ref "$ref" "$src"
      fi ;;
    local)
      if grep -q "local-plugins/$src\]" <<<"$installed"; then
        echo "ok      local:$src"
      else
        echo "link    local:$src"
        if [[ -n $target ]]; then
          ssh -n "$target" 'herdr plugin link "${DOTFILES:-$HOME/.dotfiles}/.config/herdr/local-plugins/'"$src"'"'
        else
          herdr plugin link "$dotfiles/.config/herdr/local-plugins/$src"
        fi
      fi ;;
  esac
done <"$list"

# which-key reads its key map from the plugin config dir; point it at the tracked copy
link_keys='ln -sfn "${DOTFILES:-$HOME/.dotfiles}/.config/herdr/which-key/keys.toml" "$(herdr plugin config-dir pradyb.which-key)/keys.toml"'
if [[ -n $target ]]; then ssh -n "$target" "$link_keys"; else bash -c "$link_keys"; fi

# herdr-task-runner's sidebar.py reads its settings from the plugin config dir; point it at the tracked copy
link_cfg='ln -sfn "${DOTFILES:-$HOME/.dotfiles}/.config/herdr/herdr-task-runner/config.toml" "$(herdr plugin config-dir herdr-task-runner)/config.toml"'
if [[ -n $target ]]; then ssh -n "$target" "$link_cfg"; else bash -c "$link_cfg"; fi

# key bindings call ~/.config/herdr/local-plugins/herdr-task-runner/bin/herdr-run; ~/.config/herdr is a real dir on this
# machine (runtime state), so link it. On the remote ~/.config is already one symlink into the dotfiles.
if [[ -z $target && ! -e $HOME/.config/herdr/local-plugins ]]; then
  ln -s "$dotfiles/.config/herdr/local-plugins" "$HOME/.config/herdr/local-plugins"
fi

# register herdr-run and herdr-run-hold by name, in a directory that is on PATH (also for the herdr server, key bindings
# and popups, whose PATH doesn't come from shell.sh), so the line herdr-run types into a pane is just `herdr-run-hold`
link_bin='bin="${XDG_BIN_HOME:-$HOME/.local/bin}"; mkdir -p "$bin"; for t in herdr-run herdr-run-hold; do ln -sfn "${DOTFILES:-$HOME/.dotfiles}/.config/herdr/local-plugins/herdr-task-runner/bin/$t" "$bin/$t"; done'
if [[ -n $target ]]; then ssh -n "$target" "$link_bin"; else bash -c "$link_bin"; fi

h server reload-config >/dev/null
