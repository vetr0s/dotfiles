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

deployment_home="$test_root/deployment-home"
mkdir -p "$deployment_home"
printf 'previous git config\n' > "$deployment_home/.gitconfig"
HOME="$deployment_home" bash setup.sh --platform macos >/dev/null
[ "$(readlink "$deployment_home/.gitconfig")" = "$ROOT/gitconfig" ]
backup="$(find "$deployment_home" -maxdepth 1 -name '.gitconfig.backup.*' -print)"
[ -f "$backup" ]
grep -Fxq 'previous git config' "$backup"
HOME="$deployment_home" bash setup.sh --platform macos >/dev/null
[ "$(find "$deployment_home" -maxdepth 1 -name '.gitconfig.backup.*' -print \
  | wc -l | tr -d ' ')" -eq 1 ]
HOME="$deployment_home" bash setup.sh --platform linux >/dev/null
[ "$(readlink "$deployment_home/.config/systemd/user/emacs.service")" \
  = "$ROOT/linux/systemd/emacs.service" ]

if command -v jq >/dev/null 2>&1; then
  jq empty macos/karabiner/karabiner.json
  jq -e \
    '[.profiles[].complex_modifications.rules[].manipulators[]
      | select(.from.key_code == "f3")] as $handlers
      | ($handlers | length == 1)
        and ($handlers[0].to_if_alone[0].key_code == "f3")' \
    macos/karabiner/karabiner.json >/dev/null
fi
if command -v plutil >/dev/null 2>&1; then
  plutil -lint macos/emacs/dev.nathantebbs.emacs.plist >/dev/null
fi

bash tests/shell/repo-tests.sh

if command -v emacs >/dev/null 2>&1; then
  emacs --batch -Q \
    --eval '(setq user-emacs-directory (file-name-as-directory (expand-file-name "emacs" (or (getenv "XDG_DATA_HOME") "~/.local/share"))) package-user-dir (expand-file-name "elpa" user-emacs-directory))' \
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
  nvim_data_home="${XDG_DATA_HOME:-$HOME/.local/share}/nvim"
  mkdir -p "$test_root/nvim-data/nvim"
  if [ -d "$nvim_data_home" ]; then
    cp -R "$nvim_data_home/." "$test_root/nvim-data/nvim/"
  fi
  XDG_CONFIG_HOME="$deployment_home/.config" \
    XDG_DATA_HOME="$test_root/nvim-data" \
    XDG_STATE_HOME="$test_root/nvim-state" \
    XDG_CACHE_HOME="$test_root/nvim-cache" \
    NVIM_LOG_FILE="$test_root/nvim.log" \
    nvim --headless -u "$deployment_home/.config/nvim/init.lua" -i NONE \
      -l tests/nvim/editor-tests.lua
else
  printf 'SKIP: nvim is unavailable\n'
fi

printf 'All available test suites passed\n'
