#!/bin/sh

set -eu

if [ -r /proc/device-tree/compatible ] \
  && grep -aq 'apple,' /proc/device-tree/compatible; then
  exec swaybg -i "$HOME/Pictures/mountain.jpg" -m fill
fi

exec hyprpaper
