#!/usr/bin/env bash

set -u

# ps reports a decayed per-process average, which avoids the one-second sample top needs.
usage="$(ps -A -o %cpu= | awk -v cores="$(sysctl -n hw.logicalcpu)" '{ sum += $1 } END { printf "%.0f%%", sum / cores }')"
sketchybar --set "$NAME" label="${usage:-?}"
