#!/usr/bin/env bash

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
STATE_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/emacs"
STRAIGHT_REPO="$STATE_DIR/straight/repos/straight.el"
LOCK_FILE="$DOTFILES_DIR/.emacs.d/straight-lock.el"

if ! command -v git >/dev/null 2>&1 || ! command -v emacs >/dev/null 2>&1; then
  printf 'bootstrap-emacs.sh requires Git and Emacs.\n' >&2
  exit 1
fi

if [ ! -f "$LOCK_FILE" ]; then
  printf 'Straight lockfile not found: %s\n' "$LOCK_FILE" >&2
  exit 1
fi

locked_repositories() {
  sed -n \
    's/^ *[(]*"\([^"]*\)" . "\([0-9a-f]\{40\}\)"[)]*$/\1 \2/p' \
    "$LOCK_FILE"
}

STRAIGHT_REVISION="$(locked_repositories \
  | awk '$1 == "straight.el" { print $2 }')"
if [ -z "$STRAIGHT_REVISION" ]; then
  printf 'Straight lockfile does not pin straight.el: %s\n' "$LOCK_FILE" >&2
  exit 1
fi

if [ -e "$STRAIGHT_REPO" ]; then
  if [ ! -d "$STRAIGHT_REPO/.git" ]; then
    printf 'Straight path is not a Git checkout: %s\n' "$STRAIGHT_REPO" >&2
    exit 1
  fi
  if [ -n "$(git -C "$STRAIGHT_REPO" status --short)" ]; then
    printf 'Straight checkout has local changes: %s\n' "$STRAIGHT_REPO" >&2
    exit 1
  fi
else
  mkdir -p "$(dirname "$STRAIGHT_REPO")"
  temporary="$(mktemp -d "$(dirname "$STRAIGHT_REPO")/.straight.XXXXXX")"
  trap 'rm -rf "$temporary"' EXIT
  git clone --filter=blob:none --no-checkout \
    https://github.com/radian-software/straight.el.git "$temporary"
  git -C "$temporary" checkout --detach "$STRAIGHT_REVISION"
  mv "$temporary" "$STRAIGHT_REPO"
  trap - EXIT
fi

if ! git -C "$STRAIGHT_REPO" cat-file -e "$STRAIGHT_REVISION^{commit}" 2>/dev/null; then
  git -C "$STRAIGHT_REPO" fetch origin "$STRAIGHT_REVISION"
fi
git -C "$STRAIGHT_REPO" checkout --detach "$STRAIGHT_REVISION"

# Register recipes and clone repositories that are absent on a fresh machine.
RC_EMACS_BOOTSTRAP=1 emacs --batch \
  --init-directory "$DOTFILES_DIR/.emacs.d" \
  --load "$DOTFILES_DIR/.emacs.d/early-init.el" \
  --load "$DOTFILES_DIR/.emacs.d/init.el"

# straight-thaw-versions prompts when a clean checkout is detached behind its
# default branch, which cannot work in batch mode. Restore the same lock
# directly, while refusing to overwrite actual local file changes.
while read -r repository revision; do
  checkout="$STATE_DIR/straight/repos/$repository"
  if [ ! -d "$checkout/.git" ]; then
    printf 'Locked Straight repository is absent: %s\n' "$repository" >&2
    exit 1
  fi
  if [ -n "$(git -C "$checkout" status --short)" ]; then
    printf 'Straight package has local changes: %s\n' "$checkout" >&2
    exit 1
  fi
  if ! git -C "$checkout" cat-file -e "$revision^{commit}" 2>/dev/null; then
    git -C "$checkout" fetch --tags origin
  fi
  git -C "$checkout" checkout --quiet --detach "$revision"
done < <(locked_repositories)

RC_EMACS_BOOTSTRAP=1 emacs --batch \
  --init-directory "$DOTFILES_DIR/.emacs.d" \
  --load "$DOTFILES_DIR/.emacs.d/early-init.el" \
  --load "$DOTFILES_DIR/.emacs.d/init.el" \
  --eval '(straight-rebuild-all)'

printf 'Emacs packages restored from %s\n' "$LOCK_FILE"
