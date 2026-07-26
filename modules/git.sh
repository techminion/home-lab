#!/usr/bin/env bash
# modules/git.sh - symlink base gitconfig + apply identity from config.env.

module_git() {
  # Tracked base config (aliases, colors, defaults) lives in the repo.
  link_file "$REPO_DIR/dotfiles/gitconfig" "$HOME/.gitconfig_base"

  # ~/.gitconfig includes the base, then layers identity on top so identity
  # stays out of the repo. Written once; identity via `git config` is idempotent.
  if ! grep -q 'gitconfig_base' "$HOME/.gitconfig" 2>/dev/null; then
    log "Wiring ~/.gitconfig to include base config"
    git config --global include.path "$HOME/.gitconfig_base"
  fi

  [[ -n "${GIT_USER_NAME:-}"  ]] && git config --global user.name  "$GIT_USER_NAME"
  [[ -n "${GIT_USER_EMAIL:-}" ]] && git config --global user.email "$GIT_USER_EMAIL"

  if [[ -n "${GIT_SIGNING_KEY:-}" ]]; then
    log "Enabling SSH commit signing"
    git config --global gpg.format ssh
    git config --global user.signingkey "$GIT_SIGNING_KEY"
    git config --global commit.gpgsign true
  fi
  log "git identity configured"
}
