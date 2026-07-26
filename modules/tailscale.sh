#!/usr/bin/env bash
# modules/tailscale.sh - install Tailscale and bring the device online.
# Auth is interactive: `tailscale up` prints a login URL to open in a browser.

module_tailscale() {
  if ! have tailscale; then
    log "Installing Tailscale"
    if [[ "$OS" == "macos" ]]; then
      # CLI + daemon via brew; the Mac App Store build is GUI-only.
      brew install tailscale
      $SUDO brew services start tailscale 2>/dev/null || brew services start tailscale
    else
      # Official script detects distro (RHEL, Debian/RPi OS, etc.) and adds the repo.
      curl -fsSL https://tailscale.com/install.sh | sh
      $SUDO systemctl enable --now tailscaled
    fi
  else
    log "Tailscale already installed"
  fi

  # Already connected? Don't re-trigger login.
  if tailscale status >/dev/null 2>&1; then
    log "Tailscale already connected:"
    tailscale ip -4 2>/dev/null | sed 's/^/    /'
    return
  fi

  local up_args=(${TAILSCALE_FLAGS:-})
  [[ -n "${TAILSCALE_HOSTNAME:-}" ]] && up_args+=(--hostname "$TAILSCALE_HOSTNAME")

  warn "Opening Tailscale login. Copy the URL below into a browser to authorize this device."
  $SUDO tailscale up "${up_args[@]}"
  log "Tailscale up. Addresses:"
  tailscale ip -4 2>/dev/null | sed 's/^/    /'
}
