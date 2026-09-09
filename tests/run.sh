#!/usr/bin/env bash

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

bash -n setup.sh config.bash bashrc macos/config.bash linux/config.bash \
  util/scripts/*.sh macos/scripts/*.sh tests/*.sh tests/shell/*.sh

test_root="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-tests.XXXXXX")"
trap 'rm -rf "$test_root"' EXIT

HOME="$test_root/home" bash setup.sh --dry-run --platform macos >/dev/null
HOME="$test_root/home" bash setup.sh --dry-run --platform linux >/dev/null

if command -v jq >/dev/null 2>&1; then
  jq empty macos/karabiner/karabiner.json
fi
if command -v plutil >/dev/null 2>&1; then
  plutil -lint macos/emacs/dev.nathantebbs.emacs.plist >/dev/null
fi

bash tests/shell/repo-tests.sh

if command -v emacs >/dev/null 2>&1; then
  emacs --batch -Q \
    --eval '(setq user-emacs-directory (file-name-as-directory (expand-file-name "~/.local/share/emacs")) package-user-dir (expand-file-name "elpa" user-emacs-directory))' \
    --funcall package-initialize \
    -L .emacs.d/configs \
    -l tests/emacs/editor-tests.el \
    --funcall ert-run-tests-batch-and-exit
else
  printf 'SKIP: emacs is unavailable\n'
fi

if command -v vim >/dev/null 2>&1; then
  vim -Nu .vimrc -n -es -c 'qa!'
else
  printf 'SKIP: vim is unavailable\n'
fi

if command -v nvim >/dev/null 2>&1; then
  XDG_STATE_HOME="$test_root/nvim-state" \
    XDG_CACHE_HOME="$test_root/nvim-cache" \
    NVIM_LOG_FILE="$test_root/nvim.log" \
    nvim --headless -u nvim/init.lua -i NONE -l tests/nvim/editor-tests.lua
else
  printf 'SKIP: nvim is unavailable\n'
fi

printf 'All available test suites passed\n'
