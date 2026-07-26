#!/usr/bin/env bash
# modules/packages.sh - base CLI tools common to every device.
# Installs packages one at a time so a single missing package can't abort the
# whole transaction (dnf/apt fail the entire run otherwise).

module_packages() {
  log "Installing base packages"
  local common=(git curl wget vim tmux htop tree jq unzip fzf ripgrep bat)

  case "$PKG" in
    brew)
      have brew || {
        log "Installing Homebrew"
        NONINTERACTIVE=1 /bin/bash -c \
          "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        [[ -x /opt/homebrew/bin/brew ]] && eval "$(/opt/homebrew/bin/brew shellenv)"
        [[ -x /usr/local/bin/brew   ]] && eval "$(/usr/local/bin/brew shellenv)"
      }
      # zsh is critical: fail loudly if it won't install.
      brew install zsh || die "Failed to install zsh"
      _install_each brew "${common[@]}"
      ;;

    dnf)
      _setup_epel_rhel
      $SUDO dnf makecache -q 2>/dev/null || true
      # util-linux-user provides chsh on RHEL; zsh is critical.
      $SUDO dnf install -y zsh util-linux-user || die "Failed to install zsh"
      _install_each dnf "${common[@]}"
      ;;

    apt)
      $SUDO apt-get update -y
      $SUDO apt-get install -y zsh || die "Failed to install zsh"
      _install_each apt "${common[@]}"
      ;;
  esac
}

# Enable EPEL on RHEL-family so htop/fzf/ripgrep/bat resolve.
# RHEL 10 needs the Fedora epel-release RPM + CodeReady Builder (CRB);
# Rocky/Alma/Fedora ship epel-release (and 'crb') directly.
_setup_epel_rhel() {
  if $SUDO dnf repolist enabled 2>/dev/null | grep -qi '^epel'; then
    log "EPEL already enabled"
    return
  fi
  log "Enabling EPEL"

  # Derive major version from /etc/os-release (re-source locally to be safe).
  local major arch_id
  [[ -f /etc/os-release ]] && . /etc/os-release
  major="${VERSION_ID%%.*}"
  arch_id="$(uname -m)"

  # Rocky/Alma/CentOS Stream: epel-release is in the default repos.
  if $SUDO dnf install -y epel-release 2>/dev/null; then
    $SUDO dnf config-manager --set-enabled crb 2>/dev/null || true
    return
  fi

  # True RHEL: enable CodeReady Builder via subscription-manager, then the RPM.
  if have subscription-manager; then
    $SUDO subscription-manager repos --enable "codeready-builder-for-rhel-${major}-${arch_id}-rpms" 2>/dev/null || \
      warn "Could not enable CodeReady Builder (system may be unregistered)"
  fi
  $SUDO dnf install -y "https://dl.fedoraproject.org/pub/epel/epel-release-latest-${major}.noarch.rpm" 2>/dev/null || \
    warn "Could not install epel-release RPM; some packages may be unavailable"
}

# Install packages individually; skip and warn on any that don't resolve.
_install_each() {
  local mgr="$1"; shift
  local pkg
  for pkg in "$@"; do
    case "$mgr" in
      brew) brew install "$pkg" 2>/dev/null && log "  ok: $pkg" || warn "  skipped: $pkg (unavailable)" ;;
      dnf)  $SUDO dnf install -y "$pkg" >/dev/null 2>&1 && log "  ok: $pkg" || warn "  skipped: $pkg (unavailable)" ;;
      apt)  $SUDO apt-get install -y "$pkg" >/dev/null 2>&1 && log "  ok: $pkg" || warn "  skipped: $pkg (unavailable)" ;;
    esac
  done
}