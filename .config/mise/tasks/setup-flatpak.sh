#!/usr/bin/env bash
# Usage: mise run setup-flatpak
# Installs flatpak if missing and adds the Flathub system remote. Runs as a
# pre-packages hook so the `flatpak:` packages can be installed afterwards.
# Needs sudo (or root); skipped on macOS.
set -euo pipefail

[[ "$(uname -s)" == "Linux" ]] || { echo "Not Linux; skipping flatpak setup."; exit 0; }

as_root() { if [[ $EUID -eq 0 ]]; then "$@"; else sudo "$@"; fi; }

if ! command -v flatpak >/dev/null 2>&1; then
  echo "Installing flatpak..."
  if command -v dnf >/dev/null 2>&1; then as_root dnf install -y flatpak
  elif command -v pacman >/dev/null 2>&1; then as_root pacman -S --noconfirm --needed flatpak
  elif command -v apt-get >/dev/null 2>&1; then as_root apt-get install -y flatpak
  else echo "No supported package manager found for flatpak." >&2; exit 1
  fi
fi

if flatpak remotes --system --columns=name | grep -qx flathub; then
  echo "Flathub is already configured."
  exit 0
fi

echo "Adding Flathub system remote..."
as_root flatpak remote-add --system --if-not-exists flathub \
  https://dl.flathub.org/repo/flathub.flatpakrepo
