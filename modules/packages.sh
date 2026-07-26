#!/usr/bin/env bash
# modules/packages.sh - base CLI tools common to every device.

module_packages() {
  log "Installing base packages"
  local common=(git curl wget vim tmux htop tree jq unzip fzf)

  case "$PKG" in
    brew)
      have brew || {
        log "Installing Homebrew"
        NONINTERACTIVE=1 /bin/bash -c \
          "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        [[ -x /opt/homebrew/bin/brew ]] && eval "$(/opt/homebrew/bin/brew shellenv)"
        [[ -x /usr/local/bin/brew   ]] && eval "$(/usr/local/bin/brew shellenv)"
      }
      pkg_install zsh "${common[@]}" ripgrep bat ;;
    dnf)
      $SUDO dnf install -y epel-release 2>/dev/null || true
      # util-linux-user provides chsh on RHEL
      pkg_install zsh util-linux-user "${common[@]}" || true
      pkg_install ripgrep bat 2>/dev/null || warn "ripgrep/bat unavailable (need EPEL)" ;;
    apt)
      $SUDO apt-get update -y
      # On Debian bat installs as batcat; ripgrep is ripgrep.
      pkg_install zsh "${common[@]}" ripgrep bat || true ;;
  esac
}
