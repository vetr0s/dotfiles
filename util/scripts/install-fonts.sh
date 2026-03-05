#!/usr/bin/env bash
set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
FONTS_SRC="$DOTFILES_DIR/fonts"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Determine font install directory
case "$OSTYPE" in
  darwin*)
    FONTS_DEST="$HOME/Library/Fonts"
    ;;
  linux*)
    FONTS_DEST="$HOME/.local/share/fonts"
    ;;
  *)
    echo -e "${RED}[ERROR]${NC} Unsupported OS: $OSTYPE"
    exit 1
    ;;
esac

mkdir -p "$FONTS_DEST"

if [ ! -d "$FONTS_SRC" ] || [ -z "$(ls -A "$FONTS_SRC" 2>/dev/null)" ]; then
  echo -e "${YELLOW}[INFO]${NC} No fonts found in $FONTS_SRC"
  echo ""
  echo "To install Zenbones Brainy:"
  echo "  1. Download the font files (.ttf/.otf) and place them in:"
  echo "     $FONTS_SRC"
  echo "  2. Re-run this script"
  exit 0
fi

echo "Installing fonts from $FONTS_SRC -> $FONTS_DEST"
echo ""

count=0
for font in "$FONTS_SRC"/*.ttf "$FONTS_SRC"/*.otf "$FONTS_SRC"/*.TTF "$FONTS_SRC"/*.OTF; do
  [ -f "$font" ] || continue
  name="$(basename "$font")"
  if [ -f "$FONTS_DEST/$name" ]; then
    echo -e "${GREEN}[OK]${NC} $name already installed"
  else
    cp "$font" "$FONTS_DEST/$name"
    echo -e "${GREEN}[OK]${NC} Installed $name"
  fi
  count=$((count + 1))
done

if [ "$count" -eq 0 ]; then
  echo -e "${YELLOW}[INFO]${NC} No .ttf/.otf files found in $FONTS_SRC"
  exit 0
fi

# Refresh font cache (Linux only)
if command -v fc-cache >/dev/null 2>&1; then
  fc-cache -f "$FONTS_DEST"
  echo -e "${GREEN}[OK]${NC} Font cache updated"
fi

echo ""
echo -e "${GREEN}[OK]${NC} Font installation complete ($count font(s) installed)"
