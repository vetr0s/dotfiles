#!/usr/bin/env bash

set -u

battery="$(pmset -g batt | awk -F '[;%]' 'NR == 2 { gsub(/^.*\t/, "", $1); print $1 "%" }')"
sketchybar --set "$NAME" label="${battery:-AC}"
