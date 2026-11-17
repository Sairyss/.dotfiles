#!/usr/bin/env bash
# Usage: install-mise.sh --base | --host | --apps
# Installs mise if it is missing, then previews `mise bootstrap` as a dry run
# (nothing is applied). --base uses the shared config (-E base), for
# containers/VMs; --host uses only the host-only config (-E host), so run both
# on a host machine (config.toml is always included). Run
# install.sh first so the mise config is in ~/.config/mise.
# Both also pick where the tools come from: Homebrew (e.g. -E base,brew) when
# it is available, else the distro's package manager (-E base,native); inside a
# toolbx/podman container it is always the latter. Override with
# TOOLS_SOURCE=brew|native. --base with `native` also adds the runtimes env.
# Installed with the system package manager: pacman (Arch), dnf (Fedora, via
# the upstream rpm repo), brew (macOS and immutable/ostree Fedora, where brew
# must already be installed). Other distros use the upstream installer;
# override with MISE_INSTALL_URL.
set -euo pipefail

have() { command -v "$1" >/dev/null 2>&1; }
as_root() { if [[ $EUID -eq 0 ]]; then "$@"; else sudo "$@"; fi; }

case "${1:-}" in
  --base) envs=base ;;
  --host) envs=host ;;
  --apps) envs=apps ;;
  *) echo "Usage: ${0##*/} --base | --host | --apps" >&2; exit 2 ;;
esac

# Linuxbrew is preinstalled on some immutable distros but is often not on PATH
# in a non-login shell (e.g. under curl | bash).
for b in /home/linuxbrew/.linuxbrew/bin/brew "$HOME/.linuxbrew/bin/brew"; do
  if ! have brew && [[ -x "$b" ]]; then eval "$("$b" shellenv)"; fi
done

# Desktop apps use Flatpak/casks, so they don't need the tools source.
if [[ "$envs" != "apps" ]]; then
  if [[ -z "${TOOLS_SOURCE:-}" ]]; then
    if [[ -e /run/.toolboxenv || -e /run/.containerenv ]]; then
      # Toolbx/distrobox share $HOME and PATH, so the host's brew can be visible.
      TOOLS_SOURCE=native
    elif have brew; then TOOLS_SOURCE=brew
    else TOOLS_SOURCE=native
    fi
  fi
  case "$TOOLS_SOURCE" in
    brew|native) envs="$envs,$TOOLS_SOURCE" ;;
    *) echo "TOOLS_SOURCE must be brew or native." >&2; exit 2 ;;
  esac
  # Runtimes only come from the distro's package manager, and only in containers/VMs.
  [[ "$envs" == "base,native" ]] && envs="$envs,runtimes"
fi
env_args=(-E "$envs")

# The fallback installer puts mise in ~/.local/bin, which may not be on PATH yet.
export PATH="$HOME/.local/bin:$PATH"

install_upstream() {
  have curl || { echo "curl is required to install mise." >&2; exit 1; }
  curl -fsSL "${MISE_INSTALL_URL:-https://mise.run}" | sh
}

install_mise() {
  if [[ "$(uname -s)" == "Darwin" ]]; then
    have brew || { echo "Homebrew is required to install mise on macOS." >&2; exit 1; }
    brew install mise
  elif [[ -e /run/ostree-booted ]]; then
    # Immutable Fedora: layering needs a reboot, so Homebrew has to be installed first.
    have brew || { echo "Homebrew is required to install mise here; install it first." >&2; exit 1; }
    brew install mise
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

echo "Bootstrap dry run (${env_args[*]}):"
mise "${env_args[@]}" bootstrap --dry-run
echo
echo "Looks right? Apply with: mise ${env_args[*]} bootstrap --update"
