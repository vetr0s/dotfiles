#!/usr/bin/env bash

set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
repositories=()
packages=()
purposes=()
missing_official=()
missing_aur=()
declare -A seen=()

if ! command -v pacman >/dev/null 2>&1; then
  printf 'This package manifest targets Arch Linux and requires pacman.\n' >&2
  exit 1
fi

load_manifest() {
  local manifest="$1"

  while IFS=$'\t' read -r repository package purpose extra; do
    [ -z "$repository" ] && continue
    case "$repository" in \#*) continue ;; esac
    if [ -z "$package" ] || [ -z "$purpose" ] || [ -n "$extra" ]; then
      printf 'Invalid package row in %s: %s\n' "$manifest" "$package" >&2
      exit 1
    fi
    case "$repository" in
      official|aur) ;;
      *) printf 'Unknown package repository: %s\n' "$repository" >&2; exit 1 ;;
    esac
    if [ -n "${seen[$package]:-}" ]; then
      printf 'Duplicate package: %s\n' "$package" >&2
      exit 1
    fi
    seen[$package]=1
    repositories+=("$repository")
    packages+=("$package")
    purposes+=("$purpose")
  done < "$manifest"
}

load_manifest "$DOTFILES_DIR/linux/packages.tsv"
if [ -r /proc/device-tree/compatible ] \
  && grep -aq 'apple,' /proc/device-tree/compatible; then
  load_manifest "$DOTFILES_DIR/linux/packages-asahi.tsv"
else
  load_manifest "$DOTFILES_DIR/linux/packages-generic.tsv"
fi

for i in "${!packages[@]}"; do
  package="${packages[$i]}"
  if pacman -Q -- "$package" >/dev/null 2>&1; then
    continue
  fi
  printf 'MISSING  %-32s %s\n' "$package" "${purposes[$i]}"
  if [ "${repositories[$i]}" = official ]; then
    missing_official+=("$package")
  else
    missing_aur+=("$package")
  fi
done

if [ "${#missing_official[@]}" -eq 0 ] && [ "${#missing_aur[@]}" -eq 0 ]; then
  printf 'All declared Arch packages are installed.\n'
  exit 0
fi

if [ "${#missing_official[@]}" -gt 0 ]; then
  printf '\nInstall the missing official packages with:\n  sudo pacman -Syu --needed'
  printf ' %q' "${missing_official[@]}"
  printf '\n'
fi

if [ "${#missing_aur[@]}" -gt 0 ]; then
  printf '\nInstall the missing AUR packages with your existing yay setup:\n  yay -S --needed'
  printf ' %q' "${missing_aur[@]}"
  printf '\n'
fi
