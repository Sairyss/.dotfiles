#!/usr/bin/env bash
# Usage: curl -fsSL https://raw.githubusercontent.com/Sairyss/.dotfiles/master/install.sh | bash
# One-command setup: installs git and stow if missing, clones the dotfiles
# into ~/.dotfiles (or updates an existing clone) and stows them into $HOME.
# Overrides: DOTFILES_REPO (clone URL), DOTFILES_DIR (clone location).
# Supports Fedora, Arch, Debian/Ubuntu and macOS. On immutable (ostree) systems
# git and Homebrew must already be installed; stow is then installed with brew.
# Needs sudo (or root) on Linux, except where brew is used.
set -euo pipefail

REPO="${DOTFILES_REPO:-https://github.com/Sairyss/.dotfiles.git}"
DEST="${DOTFILES_DIR:-$HOME/.dotfiles}"

as_root() { if [[ $EUID -eq 0 ]]; then "$@"; else sudo "$@"; fi; }
have() { command -v "$1" >/dev/null 2>&1; }

# Linuxbrew is preinstalled on some immutable distros but is often not on PATH
# in a non-login shell (e.g. under curl | bash).
for b in /home/linuxbrew/.linuxbrew/bin/brew "$HOME/.linuxbrew/bin/brew"; do
  if ! have brew && [[ -x "$b" ]]; then eval "$("$b" shellenv)"; fi
done

install_packages() {
  if [[ "$(uname -s)" == "Darwin" ]]; then
    # git comes with the Xcode CLT; it needs a GUI install we can't wait for.
    if ! have git; then
      xcode-select --install || true
      echo "Finish the Xcode Command Line Tools install, then re-run this script." >&2
      exit 1
    fi
    have brew || { echo "Homebrew is required to install: $*" >&2; exit 1; }
    brew install "$@"
  elif [[ -e /run/ostree-booted ]]; then
    # Immutable distro: layering needs a reboot and Homebrew itself needs git,
    # so git and Homebrew have to be installed by hand first.
    local errs=()
    case " $* " in
      *" git "*) errs+=("git is missing: layer it first (e.g. rpm-ostree install git), reboot, then re-run.") ;;
    esac
    case " $* " in
      *" stow "*) have brew || errs+=("Homebrew is missing: install it first; it is used to install stow.") ;;
    esac
    if ((${#errs[@]})); then printf '%s\n' "${errs[@]}" >&2; exit 1; fi
    brew install "$@"
  elif have dnf; then as_root dnf install -y "$@"
  elif have pacman; then as_root pacman -S --noconfirm --needed "$@"
  elif have apt-get; then as_root apt-get update && as_root apt-get install -y "$@"
  else echo "No supported package manager found." >&2; exit 1
  fi
}

missing=()
have git || missing+=(git)
have stow || missing+=(stow)
if ((${#missing[@]})); then
  echo "Installing: ${missing[*]}"
  install_packages "${missing[@]}"
fi

if [[ -d "$DEST/.git" ]]; then
  echo "$DEST already exists; skipping clone."
else
  # Submodules (e.g. shell plugins) are part of the configs.
  git clone --recurse-submodules "$REPO" "$DEST"
fi

# The repo is a single stow package named after its directory. Stow refuses to
# overwrite existing real files and reports them as conflicts.
stow --no-folding --dir="$(dirname "$DEST")" --target="$HOME" "$(basename "$DEST")"
echo "Dotfiles stowed into $HOME."
