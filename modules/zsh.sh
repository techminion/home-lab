#!/usr/bin/env bash
# modules/zsh.sh - oh-my-zsh, plugins, and symlink tracked dotfiles.

module_zsh() {
  export ZSH="${ZSH:-$HOME/.oh-my-zsh}"
  if [[ ! -d "$ZSH" ]]; then
    log "Installing oh-my-zsh"
    RUNZSH=no CHSH=no KEEP_ZSHRC=yes \
      sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
  else
    log "oh-my-zsh present"
  fi

  local custom="${ZSH_CUSTOM:-$ZSH/custom}"
  _clone() {
    local dest="$custom/plugins/$1"
    [[ -d "$dest" ]] || { log "plugin: $1"; git clone --depth=1 "$2" "$dest"; }
  }
  _clone zsh-autosuggestions     https://github.com/zsh-users/zsh-autosuggestions
  _clone zsh-syntax-highlighting https://github.com/zsh-users/zsh-syntax-highlighting

  # Symlink tracked dotfiles (REPO_DIR set by bootstrap.sh)
  link_file "$REPO_DIR/dotfiles/zshrc"    "$HOME/.zshrc"
  link_file "$REPO_DIR/dotfiles/tmux.conf" "$HOME/.tmux.conf"

  # Set default shell to zsh
  local zsh_path; zsh_path="$(command -v zsh)"
  if [[ "${SHELL:-}" != "$zsh_path" ]]; then
    log "Setting default shell to zsh"
    grep -qx "$zsh_path" /etc/shells 2>/dev/null || echo "$zsh_path" | $SUDO tee -a /etc/shells >/dev/null
    $SUDO chsh -s "$zsh_path" "$USER" 2>/dev/null || chsh -s "$zsh_path" 2>/dev/null || \
      warn "Could not change shell automatically; run: chsh -s $zsh_path"
  fi
}
