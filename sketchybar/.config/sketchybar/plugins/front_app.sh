#!/usr/bin/env bash

set -u

app="${INFO:-}"
if [ -z "$app" ]; then
  app="$(aerospace list-windows --focused --format '%{app-name}' 2>/dev/null || true)"
fi

sketchybar --set "$NAME" label="${app:-Desktop}"
