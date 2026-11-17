#!/usr/bin/env bash
# Usage: install-mise.sh --base | --host | --apps
# Installs mise if it is missing, then previews `mise bootstrap` as a dry run
# (nothing is applied). --base uses the shared config (-E base), for
# containers/VMs; --host uses only the host-only config (-E host), so run both
# on a host machine (config.toml is always included). Run
# install.sh first so the mise config is in ~/.config/mise.
# --base also picks where the tools come from, in this order: nix, Homebrew,
# the distro's package manager (whichever are installed); inside a toolbx/podman
# container it is always the distro's. Override with
# TOOLS_SOURCE=auto|nix|brew|native. --host is always native. Packages in the
# core env (git, gcc, ...) are always native (rpm-ostree layering on immutable
# Fedora) and are previewed in a separate pass. --base with a native source
# also adds the runtimes env.
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
# Only --base gets nix/brew: --host packages (services, kernel-adjacent tools)
# have to be native.
src_env=()
prefer=""
if [[ "$envs" == "base" ]]; then
  if [[ -z "${TOOLS_SOURCE:-}" ]]; then
    if [[ -e /run/.toolboxenv || -e /run/.containerenv ]]; then
      # Toolbx/distrobox share $HOME and PATH, so the host's nix/brew can be visible.
      TOOLS_SOURCE=native
    else TOOLS_SOURCE=auto
    fi
  fi
  case "$TOOLS_SOURCE" in
    auto)
      # nix, then brew, then the distro's manager (mise skips ones it can't use)
      order=()
      have nix && order+=(nix)
      have brew && order+=(brew)
      order+=(dnf pacman apt)
      ;;
    nix) order=(nix) ;;
    brew) order=(brew) ;;
    native) order=(dnf pacman apt) ;;
    *) echo "TOOLS_SOURCE must be auto, nix, brew or native." >&2; exit 2 ;;
  esac
  prefer="$(IFS=,; echo "${order[*]}")"
  # Runtimes only come from the distro's package manager, and only in containers/VMs.
  [[ "${order[0]}" == dnf ]] && src_env+=(runtimes)
fi
envs="$(IFS=,; echo "$envs${src_env[*]:+,${src_env[*]}}")"

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

# Pinned-native packages go first, in their own pass, with the default order
# from config.toml; the rest use the order built above.
echo "Bootstrap dry run (core):"
mise -E core bootstrap --dry-run
echo
echo "Bootstrap dry run (${envs}${prefer:+, prefer $prefer}):"
if [[ -n "$prefer" ]]; then
  MISE_SYSTEM_PACKAGES_PREFER="$prefer" mise -E "$envs" bootstrap --dry-run
else
  mise -E "$envs" bootstrap --dry-run
fi
echo
echo "Looks right? Apply with:"
echo "  mise -E core bootstrap --update"
echo "  ${prefer:+MISE_SYSTEM_PACKAGES_PREFER=$prefer }mise -E $envs bootstrap --update"
