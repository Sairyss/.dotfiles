#!/usr/bin/env bash
# Install the plugins from .config/herdr/plugins.list.
# Usage: scripts/sync-plugins.sh [ssh-target]   (no target = this machine)
set -euo pipefail

list="$(dirname "$(readlink -f "$0")")/../plugins.list"
target="${1:-}"

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
        dir=".dotfiles/.config/herdr/local-plugins/$src"
        if [[ -n $target ]]; then ssh -n "$target" 'herdr plugin link "$HOME/'"$dir"'"'; else herdr plugin link "$HOME/$dir"; fi
      fi ;;
  esac
done <"$list"

# which-key reads its key map from the plugin config dir; point it at the tracked copy
link_keys='ln -sfn "$HOME/.dotfiles/.config/herdr/which-key/keys.toml" "$(herdr plugin config-dir pradyb.which-key)/keys.toml"'
if [[ -n $target ]]; then ssh -n "$target" "$link_keys"; else bash -c "$link_keys"; fi

# key bindings call ~/.config/herdr/scripts/launch.sh; ~/.config/herdr is a real dir on this machine
# (runtime state), so link it. On the remote ~/.config is already one symlink into the dotfiles.
if [[ -z $target && ! -e $HOME/.config/herdr/scripts ]]; then
  ln -s ../../.dotfiles/.config/herdr/scripts "$HOME/.config/herdr/scripts"
fi

h server reload-config >/dev/null
