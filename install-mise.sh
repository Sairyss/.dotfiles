#!/usr/bin/env bash
# Usage: install-mise.sh [--host]
# Installs mise if it is missing, then previews `mise bootstrap` as a dry run
# (nothing is applied). With --host the host-only config (config.host.toml) is
# included. Run install.sh first so the mise config is in ~/.config/mise.
# Installed with the system package manager: pacman (Arch), dnf (Fedora, via
# the upstream rpm repo), brew (macOS; immutable/ostree Fedora when brew is
# present). Immutable Fedora without brew and other distros use the upstream
# installer; override with MISE_INSTALL_URL.
set -euo pipefail

have() { command -v "$1" >/dev/null 2>&1; }
as_root() { if [[ $EUID -eq 0 ]]; then "$@"; else sudo "$@"; fi; }

env_args=()
case "${1:-}" in
  "") ;;
  --host) env_args=(-E host) ;;
  *) echo "Usage: ${0##*/} [--host]" >&2; exit 2 ;;
esac

# The fallback installer puts mise in ~/.local/bin, which may not be on PATH yet.
export PATH="$HOME/.local/bin:$PATH"

# The upstream installer puts mise in ~/.local/bin.
install_upstream() {
  have curl || { echo "curl is required to install mise." >&2; exit 1; }
  curl -fsSL "${MISE_INSTALL_URL:-https://mise.run}" | sh
}

install_mise() {
  if [[ "$(uname -s)" == "Darwin" ]]; then
    have brew || { echo "Homebrew is required to install mise on macOS." >&2; exit 1; }
    brew install mise
  elif [[ -e /run/ostree-booted ]]; then
    # Immutable Fedora: avoid layering (needs a reboot); prefer brew, else the
    # upstream installer.
    if have brew; then brew install mise; else install_upstream; fi
  elif have pacman; then
    as_root pacman -S --noconfirm --needed mise
  elif have dnf; then
    # Fedora has no mise package; use the upstream rpm repo (dnf5, then dnf4).
    repo=https://mise.jdx.dev/rpm/mise.repo
    as_root dnf config-manager addrepo --from-repofile="$repo" 2>/dev/null \
      || as_root dnf config-manager --add-repo "$repo"
    as_root dnf install -y mise
  else
    install_upstream
  fi
}

if have mise; then
  echo "mise already installed: $(mise --version)"
else
  install_mise
fi

conf="${MISE_CONFIG_DIR:-${XDG_CONFIG_HOME:-$HOME/.config}/mise}/config.toml"
[[ -e "$conf" ]] || echo "Warning: $conf not found; run install.sh first." >&2

echo "Bootstrap dry run${env_args:+ (host)}:"
mise "${env_args[@]}" bootstrap --dry-run
echo
echo "Looks right? Apply with: mise ${env_args[*]:+${env_args[*]} }bootstrap --update"
