#!/usr/bin/env bash
# lib/common.sh - shared helpers and OS detection, sourced by all modules.

log()  { printf '\033[1;32m[+]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[!]\033[0m %s\n' "$*"; }
err()  { printf '\033[1;31m[x]\033[0m %s\n' "$*" >&2; }
die()  { err "$*"; exit 1; }

# Populated by detect_os
OS=""      # macos | rhel | debian
PKG=""     # brew  | dnf  | apt
SUDO=""
ARCH=""

detect_os() {
  ARCH="$(uname -m)"
  if [[ "$(uname -s)" == "Darwin" ]]; then
    OS="macos"; PKG="brew"
  elif [[ -f /etc/os-release ]]; then
    . /etc/os-release
    case "${ID}:${ID_LIKE:-}" in
      *rhel*|*fedora*|*centos*|*rocky*|*alma*) OS="rhel";   PKG="dnf" ;;
      *debian*|*ubuntu*|*raspbian*)            OS="debian"; PKG="apt" ;;
      *)
        if   command -v dnf     >/dev/null 2>&1; then OS="rhel";   PKG="dnf"
        elif command -v apt-get >/dev/null 2>&1; then OS="debian"; PKG="apt"
        else die "Unsupported Linux distro: ${ID:-unknown}"; fi ;;
    esac
  else
    die "Unsupported OS: $(uname -s)"
  fi
  [[ $EUID -ne 0 ]] && command -v sudo >/dev/null 2>&1 && SUDO="sudo"
  log "Detected: $OS / $ARCH (pkg: $PKG)"
}

have() { command -v "$1" >/dev/null 2>&1; }

# Install one or more packages using the detected package manager.
pkg_install() {
  case "$PKG" in
    brew) brew install "$@" ;;
    dnf)  $SUDO dnf install -y "$@" ;;
    apt)  $SUDO apt-get install -y "$@" ;;
  esac
}

# Symlink src -> dest, backing up an existing real file/dir.
link_file() {
  local src="$1" dest="$2"
  mkdir -p "$(dirname "$dest")"
  if [[ -L "$dest" ]]; then
    [[ "$(readlink "$dest")" == "$src" ]] && { log "Link ok: $dest"; return; }
    rm -f "$dest"
  elif [[ -e "$dest" ]]; then
    mv "$dest" "$dest.backup.$(date +%s)"
    warn "Backed up existing $dest"
  fi
  ln -s "$src" "$dest"
  log "Linked $dest -> $src"
}
