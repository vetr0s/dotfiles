#!/usr/bin/env bash

set -u

interface="$(route -n get default 2>/dev/null | awk '/interface:/ { print $2; exit }')"
address=""
if [ -n "$interface" ]; then
  address="$(ipconfig getifaddr "$interface" 2>/dev/null || true)"
fi

if [ -n "$address" ]; then
  label="$interface $address"
else
  label="offline"
fi

sketchybar --set "$NAME" label="$label"
