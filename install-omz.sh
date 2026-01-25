#!/usr/bin/env bash
set -xe

command -v zsh >/dev/null 2>&1 || { echo "zsh not installed"; exit 1; }

# Install oh-my-zsh without taking over the session
export RUNZSH=no
export CHSH=no
export KEEP_ZSHRC=yes

sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

DIR="$(pwd)"
grep -qxF "source \"$DIR/config.zsh\"" "$HOME/.zshrc" 2>/dev/null || \
  printf '\nsource "%s/config.zsh"\n' "$DIR" >> "$HOME/.zshrc"
