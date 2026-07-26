#!/usr/bin/env bash
# modules/podman.sh - install Podman (rootless) + podman-compose.

module_podman() {
  if ! have podman; then
    log "Installing Podman"
    case "$PKG" in
      brew) brew install podman
            # macOS runs containers in a managed Linux VM.
            podman machine inspect >/dev/null 2>&1 || podman machine init
            podman machine start 2>/dev/null || true ;;
      dnf)  pkg_install podman ;;
      apt)  pkg_install podman ;;
    esac
  else
    log "Podman present"
  fi

  # podman-compose: prefer distro package, fall back to pipx/pip.
  if ! have podman-compose; then
    log "Installing podman-compose"
    case "$PKG" in
      brew) brew install podman-compose ;;
      dnf)  pkg_install podman-compose || _pip_compose ;;
      apt)  pkg_install podman-compose || _pip_compose ;;
    esac
  else
    log "podman-compose present"
  fi

  # Enable rootless socket so tools expecting a Docker socket work (Linux only).
  if [[ "$OS" != "macos" ]]; then
    systemctl --user enable --now podman.socket 2>/dev/null || \
      warn "Could not enable rootless podman.socket (ok if no systemd user session)"
    # Let rootless containers keep running after logout, and start at boot.
    loginctl enable-linger "$USER" 2>/dev/null || true
  fi

  log "Podman ready: $(podman --version 2>/dev/null)"
}

_pip_compose() {
  warn "No distro podman-compose; installing via pip"
  if have pipx; then pipx install podman-compose
  else $SUDO python3 -m pip install --user podman-compose 2>/dev/null || \
       python3 -m pip install --user podman-compose; fi
}
