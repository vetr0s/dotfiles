#!/usr/bin/env bash

set -u

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
FAILURES=0

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  FAILURES=$((FAILURES + 1))
}

if ! bash -c '
  PATH=/usr/bin:/bin
  HOME=/tmp
  DOTFILES_DIR="$1"
  OSTYPE=linux-gnu
  . "$DOTFILES_DIR/config.bash"
  case ":$PATH:" in *:.:*) exit 1 ;; esac
' _ "$ROOT"; then
  fail "config.bash adds the current directory to PATH"
fi

if ! grep -Fq 'source-file ~/.config/tmux/tmux.conf' "$ROOT/tmux/tmux.conf"; then
  fail "tmux reloads a path that deploy.sh does not create"
fi

if grep -Fq 'tmux-mem-cpu-load' "$ROOT/tmux/tmux.conf"; then
  fail "tmux calls an undeclared status helper"
fi

description="$(jq -r '.profiles[0].complex_modifications.rules[0].description' \
  "$ROOT/macos/karabiner/karabiner.json")"
if [ "$description" != "HHKB: F3 plus F1 through F3 types 1 through 3" ]; then
  fail "Karabiner describes keys that it does not map"
fi

if ! grep -Eq '^set -[^[:space:]]*o pipefail$' \
  "$ROOT/macos/scripts/kitty-float.sh"; then
  fail "kitty-float ignores failures in its window lookup"
fi

if ! grep -Fq 'cmp -s "$font" "$FONTS_DEST/$name"' \
  "$ROOT/util/scripts/install-fonts.sh"; then
  fail "install-fonts does not replace changed font files"
fi

if find "$ROOT/fonts" -type f -perm -111 -print -quit | grep -q .; then
  fail "font files have executable mode bits"
fi

if ! grep -Fq 'BUILD_ROOT="$(mktemp -d' \
  "$ROOT/macos/scripts/make-emacsclient-app.sh"; then
  fail "the Emacsclient app is not built before replacement"
fi

mock_root="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-emacsctl.XXXXXX")"
tmux_tmp="/tmp/dt.$$"
mkdir -p "$tmux_tmp"
trap 'rm -rf "$mock_root" "$tmux_tmp"' EXIT
mkdir -p "$mock_root/bin" "$mock_root/home"
printf '#!/bin/sh\nexit 0\n' > "$mock_root/bin/launchctl"
printf '#!/bin/sh\n: > "$TEST_READY_MARKER"\n' > "$mock_root/bin/emacsclient"
chmod +x "$mock_root/bin/launchctl" "$mock_root/bin/emacsclient"
export TEST_READY_MARKER="$mock_root/ready"

if ! bash -c '
  DOTFILES_DIR="$1"
  HOME="$2"
  OSTYPE=darwin
  . "$DOTFILES_DIR/config.bash"
  PATH="$3:/usr/bin:/bin"
  emacsctl start
' _ "$ROOT" "$mock_root/home" "$mock_root/bin"; then
  fail "emacsctl start failed under the test service manager"
elif [ ! -e "$TEST_READY_MARKER" ]; then
  fail "emacsctl start returns before the daemon is ready"
fi

printf '#!/bin/sh\nprintf "%%s\\n" "$*" >> "$TEST_SYSTEMCTL_LOG"\n' \
  > "$mock_root/bin/systemctl"
chmod +x "$mock_root/bin/systemctl"
export TEST_SYSTEMCTL_LOG="$mock_root/systemctl.log"
if ! bash -c '
  DOTFILES_DIR="$1"
  HOME="$2"
  OSTYPE=linux-gnu
  . "$DOTFILES_DIR/config.bash"
  PATH="$3:/usr/bin:/bin"
  emacsctl start
' _ "$ROOT" "$mock_root/home" "$mock_root/bin"; then
  fail "Linux emacsctl start failed under the test service manager"
elif ! grep -Fxq -- '--user daemon-reload' "$TEST_SYSTEMCTL_LOG" \
  || ! grep -Fxq -- '--user start emacs.service' "$TEST_SYSTEMCTL_LOG"; then
  fail "Linux emacsctl did not load and start its service"
fi

font_source="$mock_root/font-source"
font_dest="$mock_root/font-dest"
mkdir -p "$font_source" "$font_dest"
printf 'new font\n' > "$font_source/probe.ttf"
printf 'old font\n' > "$font_dest/probe.ttf"
if ! FONTS_SRC="$font_source" FONTS_DEST="$font_dest" \
  REFRESH_FONT_CACHE=0 OSTYPE=linux-gnu \
  "$ROOT/util/scripts/install-fonts.sh" >/dev/null; then
  fail "install-fonts failed under an isolated destination"
elif ! cmp -s "$font_source/probe.ttf" "$font_dest/probe.ttf"; then
  fail "install-fonts kept stale font contents"
fi

mkdir -p "$mock_root/aerospace-bin"
printf '#!/bin/sh\nexit 7\n' > "$mock_root/aerospace-bin/aerospace"
chmod +x "$mock_root/aerospace-bin/aerospace"
if PATH="$mock_root/aerospace-bin:/usr/bin:/bin" KITTY=/usr/bin/true \
  "$ROOT/macos/scripts/kitty-float.sh" >/dev/null 2>&1; then
  fail "kitty-float continued after the window query failed"
fi

old_app="$mock_root/Emacsclient.app"
emacs_app="$mock_root/Emacs.app"
mkdir -p "$old_app/Contents" "$emacs_app/Contents/MacOS/bin"
printf 'original app\n' > "$old_app/Contents/original"
printf '#!/bin/sh\nprintf "dev.nathantebbs.emacsclient\\n"\n' \
  > "$mock_root/bin/defaults"
printf '#!/bin/sh\nexit 1\n' > "$mock_root/bin/chmod"
chmod +x "$mock_root/bin/defaults" "$mock_root/bin/chmod"
if PATH="$mock_root/bin:/usr/bin:/bin" OSTYPE=darwin \
  EMACSCLIENT_APP="$old_app" EMACS_APPLICATION="$emacs_app" \
  LSREGISTER=/nonexistent "$ROOT/macos/scripts/make-emacsclient-app.sh" \
  >/dev/null 2>&1; then
  fail "the Emacsclient build fault did not fail"
elif [ ! -f "$old_app/Contents/original" ]; then
  fail "a failed Emacsclient build replaced the installed app"
fi

rm -rf "$old_app"
if ! OSTYPE=darwin EMACSCLIENT_APP="$old_app" \
  EMACS_APPLICATION="$emacs_app" LSREGISTER=/nonexistent \
  "$ROOT/macos/scripts/make-emacsclient-app.sh" >/dev/null; then
  fail "the isolated Emacsclient app build failed"
elif [ ! -x "$old_app/Contents/MacOS/emacsclient-launcher" ]; then
  fail "the generated Emacsclient launcher is not executable"
elif find "$mock_root" -maxdepth 1 -name '.Emacsclient-build.*' | grep -q .; then
  fail "the Emacsclient build left a staging directory"
fi

if command -v tmux >/dev/null 2>&1; then
  tmux_socket="dotfiles-repo-test-$$"
  TMUX_TMPDIR="$tmux_tmp" tmux -L "$tmux_socket" \
    -f "$ROOT/tmux/tmux.conf" new-session -d >/dev/null 2>&1
  if TMUX_TMPDIR="$tmux_tmp" tmux -L "$tmux_socket" \
    has-session 2>/dev/null; then
    reload="$(TMUX_TMPDIR="$tmux_tmp" tmux -L "$tmux_socket" \
      list-keys -T prefix r)"
    case "$reload" in
      *"source-file ~/.config/tmux/tmux.conf"*) ;;
      *) fail "the live tmux reload binding uses the wrong path" ;;
    esac
    TMUX_TMPDIR="$tmux_tmp" tmux -L "$tmux_socket" kill-server
  else
    printf 'SKIP: tmux server unavailable\n'
  fi
fi

if [ "$FAILURES" -ne 0 ]; then
  printf '%d repository check(s) failed\n' "$FAILURES" >&2
  exit 1
fi

printf 'All repository checks passed\n'
