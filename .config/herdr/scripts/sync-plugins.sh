#!/usr/bin/env bash
# Install the plugins from .config/herdr/plugins.list.
# Usage: herdr-sync-plugins.sh [ssh-target]   (no target = this machine)
set -euo pipefail

list="$(dirname "$(readlink -f "$0")")/plugins.list"
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

h server reload-config >/dev/null
