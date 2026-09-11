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

if grep -Fq '#(uptime |' "$ROOT/tmux/tmux.conf"; then
  fail "tmux parses platform-specific uptime output in the status bar"
fi

if ! grep -Fq '"description": "HHKB: Hold F3 with F1 or F2 to type 1 or 2"' \
  "$ROOT/macos/karabiner/karabiner.json"; then
  fail "Karabiner describes keys that it does not map"
fi

if ! grep -Eq '^set -[^[:space:]]*o pipefail$' \
  "$ROOT/macos/scripts/kitty-float.sh"; then
  fail "kitty-float ignores failures in its window lookup"
fi

if ! grep -Fq 'globinclude ${KITTY_OS}.conf' "$ROOT/kitty/kitty.conf"; then
  fail "Kitty warns about a missing platform include"
fi

if grep -Fq $'official\tttf-nerd-fonts-symbols\t' "$ROOT/linux/packages.tsv" \
  || ! grep -Fq $'official\tttf-nerd-fonts-symbols-mono\t' \
    "$ROOT/linux/packages.tsv"; then
  fail "the Arch manifest installs the wrong Nerd Font symbol family"
fi

for package in make odin; do
  if ! grep -Eq "^official[[:space:]]+$package[[:space:]]" \
    "$ROOT/linux/packages.tsv"; then
    fail "the Arch manifest omits $package"
  fi
done

if ! grep -Fq "sudo pacman -Syu --needed" \
  "$ROOT/linux/scripts/check-packages.sh"; then
  fail "the Arch package checker permits a partial upgrade"
fi

if grep -Eq $'^official\t(hyprpaper|swaybg)\t' "$ROOT/linux/packages.tsv" \
  || ! grep -Fq $'official\tswaybg\t' "$ROOT/linux/packages-asahi.tsv" \
  || ! grep -Fq $'official\thyprpaper\t' "$ROOT/linux/packages-generic.tsv"; then
  fail "wallpaper packages are not isolated by hardware profile"
fi

if ! grep -Fq 'layout = hy3_enabled and "hy3" or "dwindle"' \
  "$ROOT/linux/hypr/hyprland.lua" \
  || ! grep -Fq 'hl.plugin.load(hy3_path)' "$ROOT/linux/hypr/hyprland.lua"; then
  fail "the Hyprland config does not load hy3 with a dwindle fallback"
fi

if ! grep -Fq '42b7ed8fd9aefd3f36e5f617afd5071245c67853' \
  "$ROOT/linux/README.md"; then
  fail "the documented hy3 install does not use an immutable revision"
fi

if ! grep -Fq 'BUILD_ROOT="$(mktemp -d' \
  "$ROOT/macos/scripts/make-emacsclient-app.sh"; then
  fail "the Emacsclient app is not built before replacement"
fi

if grep -Fq 'vim-plug/master/plug.vim' \
  "$ROOT/util/scripts/install-vimplug.sh"; then
  fail "the vim-plug installer downloads a moving branch"
fi

if grep -Fq 'git -C "$SRC_DIR" pull' "$ROOT/util/scripts/install-ols.sh" \
  || ! grep -Eq "OLS_REVISION=.*[0-9a-f]{40}" \
    "$ROOT/util/scripts/install-ols.sh"; then
  fail "the OLS installer does not use an immutable revision"
fi

if ! grep -Fq 'OLS_ODIN_VERSION=' "$ROOT/util/scripts/install-ols.sh" \
  || ! grep -Fq 'worktree add --detach' "$ROOT/util/scripts/install-ols.sh" \
  || ! grep -Fq '"$BIN_DIR/.ols-current/ols"' \
    "$ROOT/util/scripts/install-ols.sh"; then
  fail "the OLS installer does not stage a compiler-pinned binary pair"
fi

if ! grep -Fq 'd2ca8efb4487e156a60d5bd6db2598b872629403' \
  "$ROOT/.emacs.d/configs/rc-odin.el"; then
  fail "the Emacs Odin grammar is not pinned"
fi

if ! grep -Fq '/opt/homebrew/opt/universal-ctags/bin' \
  "$ROOT/macos/config.bash"; then
  fail "macOS leaves Xcode ctags ahead of universal-ctags"
fi

if grep -E '^  Plug ' "$ROOT/.vimrc" | grep -Ev "'commit': '[0-9a-f]{40}'" \
  | grep -q .; then
  fail "a Vim plugin is not pinned to an immutable revision"
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

ols_revision=110e63703db100e9cd5f381328bfde99fdb4b85f
ols_odin_version=dev-2026-09:a2fb372b7
ols_release="$mock_root/ols-bin/ols-revisions/${ols_revision}-dev-2026-09_a2fb372b7"
mkdir -p "$ols_release" "$mock_root/ols-tools"
printf '#!/bin/sh\nprintf "ols version dev-test-110e6370\\n"\n' \
  > "$ols_release/ols"
printf '#!/bin/sh\nexit 0\n' > "$ols_release/odinfmt"
printf '%s\t%s\n' "$ols_revision" "$ols_odin_version" \
  > "$ols_release/BUILD-PINS"
printf '#!/bin/sh\nprintf "odin version %%s\\n" "$OLS_ODIN_VERSION"\n' \
  > "$mock_root/ols-tools/odin"
printf '#!/bin/sh\nexit 91\n' > "$mock_root/ols-tools/git"
chmod +x "$ols_release/ols" "$ols_release/odinfmt" \
  "$mock_root/ols-tools/odin" "$mock_root/ols-tools/git"
if ! PATH="$mock_root/ols-tools:/usr/bin:/bin" \
  OLS_SRC_DIR="$mock_root/unused-ols-source" \
  OLS_BIN_DIR="$mock_root/ols-bin" \
  OLS_REVISION="$ols_revision" OLS_ODIN_VERSION="$ols_odin_version" \
  "$ROOT/util/scripts/install-ols.sh" >/dev/null 2>&1; then
  fail "install-ols rebuilds an existing pinned release"
elif [ "$(readlink "$mock_root/ols-bin/.ols-current")" != "$ols_release" ]; then
  fail "install-ols did not activate the existing pinned release"
fi

tag_root="$mock_root/tag-project"
mkdir -p "$tag_root" "$mock_root/tag-bin"
printf 'old vi tags\n' > "$tag_root/tags"
printf 'old Emacs tags\n' > "$tag_root/.tags"
cat > "$mock_root/tag-bin/ctags" <<'EOF'
#!/bin/sh
if [ "${1:-}" = --version ]; then
  printf 'Universal Ctags\n'
  exit
fi
output=
previous=
emacs=0
for argument in "$@"; do
  [ "$previous" = -f ] && output="$argument"
  [ "$argument" = -e ] && emacs=1
  previous="$argument"
done
[ "$emacs" -eq 0 ] || exit 1
printf 'new vi tags\n' > "$output"
EOF
chmod +x "$mock_root/tag-bin/ctags"
if PATH="$mock_root/tag-bin:/usr/bin:/bin" \
  "$ROOT/util/scripts/tags.sh" "$tag_root" >/dev/null 2>&1; then
  fail "tags.sh ignored a failed Emacs index"
elif ! grep -Fxq 'old vi tags' "$tag_root/tags" \
  || ! grep -Fxq 'old Emacs tags' "$tag_root/.tags"; then
  fail "tags.sh exposed one new index after the other failed"
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
      list-keys -T prefix)"
    case "$reload" in
      *"source-file $HOME/.config/tmux/tmux.conf"*) ;;
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
