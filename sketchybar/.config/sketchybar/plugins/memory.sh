#!/usr/bin/env bash

set -u

usage="$(memory_pressure | awk '/System-wide memory free percentage:/ { gsub(/%/, "", $5); print 100 - $5 "%" }')"
sketchybar --set "$NAME" label="${usage:-?}"
