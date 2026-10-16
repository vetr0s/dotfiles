#!/usr/bin/env bash

set -u

title="$(aerospace list-windows --focused --format '%{window-title}' 2>/dev/null || true)"
sketchybar --set "$NAME" label="$title" drawing="$([ -n "$title" ] && printf on || printf off)"
