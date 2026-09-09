#!/usr/bin/env bash
# Summons a kitty window that draws above every other window, and is a normal
# resizable window otherwise.
#
# macOS has no system-wide always-on-top, and AeroSpace cannot add one: the
# Accessibility API exposes no window z-order, so a tiling manager can move a
# window but never raise it. kitty sets its own NSWindow level, so the window
# started here sits at NSFloatingWindowLevel and stays above ordinary windows
# without anything else being involved.
#
# AeroSpace still decides which workspace it lives on and hides the others, so
# there is no "sticky". Running this again instead drags the window to whatever
# workspace is focused now. aerospace.toml floats it on sight by matching the
# title, which -T pins against anything the shell inside tries to set.

set -euo pipefail

TITLE="kitty-float"
KITTY="${KITTY:-/Applications/kitty.app/Contents/MacOS/kitty}"

id=$(aerospace list-windows --all --format '%{window-id}|%{window-title}' \
  | awk -F'|' -v t="$TITLE" \
      '$2 == t && !found { gsub(/ /, "", $1); print $1; found = 1 }')

if [ -z "$id" ]; then
  exec "$KITTY" --detach --title "$TITLE" \
    --override macos_ns_window_layer=NSFloatingWindowLevel \
    --override remember_window_size=no \
    --override initial_window_width=100c \
    --override initial_window_height=28c
fi

aerospace move-node-to-workspace --window-id "$id" "$(aerospace list-workspaces --focused)"
aerospace focus --window-id "$id"
