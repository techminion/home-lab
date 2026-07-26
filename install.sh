#!/usr/bin/env bash
#
# install.sh - one-liner entrypoint for the home-lab repo.
#
#   curl -fsSL https://raw.githubusercontent.com/techminion/home-lab/main/install.sh | bash
#
# Clones (or updates) the repo, then hands off to bootstrap.sh. Because a piped
# script has no repo on disk, this fetches it first, then runs the real work.

set -euo pipefail

REPO_URL="${HOMELAB_REPO:-https://github.com/techminion/home-lab.git}"
DEST="${HOMELAB_DIR:-$HOME/home-lab}"

log() { printf '\033[1;32m[+]\033[0m %s\n' "$*"; }

command -v git >/dev/null 2>&1 || {
  echo "git is required. Install it first (e.g. sudo dnf install -y git / brew install git)." >&2
  exit 1
}

if [[ -d "$DEST/.git" ]]; then
  log "Updating existing checkout in $DEST"
  git -C "$DEST" pull --ff-only
else
  log "Cloning $REPO_URL -> $DEST"
  git clone --depth=1 "$REPO_URL" "$DEST"
fi

cd "$DEST"

# First run: seed config.env from the template so the user can edit it.
if [[ ! -f config.env ]]; then
  cp config.env.example config.env
  log "Created config.env from template. Edit it, then re-run to apply your settings:"
  log "  \$EDITOR $DEST/config.env && $DEST/bootstrap.sh"
fi

exec ./bootstrap.sh "$@"
