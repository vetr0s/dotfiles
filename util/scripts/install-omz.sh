#!/usr/bin/env bash
set -e

command -v zsh >/dev/null 2>&1 || { echo "zsh not installed"; exit 1; }

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# Install oh-my-zsh without taking over the session
export RUNZSH=no
export CHSH=no
export KEEP_ZSHRC=yes

sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# Source config.zsh from the dotfiles repo (absolute path so it works regardless of cwd)
SOURCE_LINE="source \"$DOTFILES_DIR/config.zsh\""
grep -qxF "$SOURCE_LINE" "$HOME/.zshrc" 2>/dev/null || \
  printf '\n%s\n' "$SOURCE_LINE" >> "$HOME/.zshrc"

echo "Sourced config.zsh in ~/.zshrc"
