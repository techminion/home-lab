#!/usr/bin/env bash
#
# bootstrap.sh - provision a device for the home lab.
# Detects OS, then runs the modules listed in config.env ($MODULES).
# Idempotent: safe to re-run whenever you change config or add a device.
#
# Usage:
#   git clone https://github.com/techminion/home-lab.git
#   cd home-lab
#   cp config.env.example config.env   # then edit
#   ./bootstrap.sh                      # run everything in $MODULES
#   ./bootstrap.sh podman tailscale     # or run only named modules

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export REPO_DIR

source "$REPO_DIR/lib/common.sh"

# Load config if present; otherwise fall back to sensible defaults.
if [[ -f "$REPO_DIR/config.env" ]]; then
  set -a; source "$REPO_DIR/config.env"; set +a
else
  warn "No config.env found — using defaults. Copy config.env.example to config.env to customize."
fi

MODULES="${MODULES:-packages zsh git podman tailscale}"
# CLI args override config's module list.
[[ $# -gt 0 ]] && MODULES="$*"

detect_os

for m in $MODULES; do
  module_file="$REPO_DIR/modules/$m.sh"
  [[ -f "$module_file" ]] || { err "Unknown module: $m"; continue; }
  source "$module_file"
  printf '\n\033[1;34m=== module: %s ===\033[0m\n' "$m"
  "module_$m"
done

printf '\n'
log "Bootstrap complete. Start a new shell or run: exec zsh"
