#!/usr/bin/env bash

set -u

source "$CONFIG_DIR/colors.sh"

focused_workspace="${FOCUSED_WORKSPACE:-}"
if [ -z "$focused_workspace" ]; then
  focused_workspace="$(aerospace list-workspaces --focused 2>/dev/null || true)"
fi

occupied_workspaces="$(aerospace list-windows --all --format '%{workspace}' 2>/dev/null | sort -u || true)"
args=()

for workspace in 1 2 3 4 5 6 7 8 9; do
  if [ "$workspace" = "$focused_workspace" ]; then
    background="$ACTIVE_COLOR"
    foreground="$CRUST_COLOR"
  elif printf '%s\n' "$occupied_workspaces" | grep -qx "$workspace"; then
    background="$ITEM_COLOR"
    foreground="$TEXT_COLOR"
  else
    background="$TRANSPARENT"
    foreground="$MUTED_COLOR"
  fi

  args+=(--set "space.$workspace" \
    background.color="$background" \
    label.color="$foreground")
done

sketchybar "${args[@]}"
