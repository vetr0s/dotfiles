#!/usr/bin/env bash

set -euo pipefail

VIM_AUTOLOAD_DIR="${VIM_AUTOLOAD_DIR:-$HOME/.vim/autoload}"
VIM_PLUG_REVISION="${VIM_PLUG_REVISION:-88e31471818e9a29a8a20a0ee61360cfd7bdc1cd}"

mkdir -p "$VIM_AUTOLOAD_DIR"
temporary="$(mktemp "$VIM_AUTOLOAD_DIR/.plug.vim.XXXXXX")"
trap 'rm -f "$temporary"' EXIT

curl --fail --location --silent --show-error --output "$temporary" \
  "https://raw.githubusercontent.com/junegunn/vim-plug/$VIM_PLUG_REVISION/plug.vim"
grep -Fq 'function! plug#begin' "$temporary"
chmod 0644 "$temporary"
mv "$temporary" "$VIM_AUTOLOAD_DIR/plug.vim"
trap - EXIT
