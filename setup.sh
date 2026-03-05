#!/usr/bin/env bash

set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

info() { echo -e "${GREEN}[OK]${NC} $*"; }
warn() { echo -e "${YELLOW}[INFO]${NC} $*"; }
err()  { echo -e "${RED}[ERROR]${NC} $*"; }

is_wsl() { grep -qi microsoft /proc/version 2>/dev/null; }

echo "=== dotfiles setup ==="
echo ""

# ── 1. System dependencies ───────────────────────────────────────────────────
echo "--- Dependencies ---"
echo ""

# package name -> command to check
declare -A DEPS=(
  [neovim]=nvim
  [emacs]=emacs
  [ripgrep]=rg
  [fzf]=fzf
  [make]=make
  [zsh]=zsh
  [curl]=curl
  [git]=git
)

missing=()
for pkg in "${!DEPS[@]}"; do
  command -v "${DEPS[$pkg]}" >/dev/null 2>&1 || missing+=("$pkg")
done

if [ ${#missing[@]} -gt 0 ]; then
  warn "Missing packages: ${missing[*]}"
  case "$OSTYPE" in
    linux*)
      sudo apt update
      sudo apt install -y "${missing[@]}"
      ;;
    darwin*)
      if ! command -v brew >/dev/null 2>&1; then
        err "Homebrew not found. Install it from https://brew.sh then re-run this script."
        exit 1
      fi
      brew install "${missing[@]}"
      ;;
    *)
      err "Unsupported OS: $OSTYPE"
      exit 1
      ;;
  esac
else
  info "All dependencies already installed"
fi

echo ""

# ── 2. Fonts ─────────────────────────────────────────────────────────────────
echo "--- Fonts ---"
echo ""
bash "$DOTFILES_DIR/util/scripts/install-fonts.sh"
echo ""

# ── 3. Symlinks ───────────────────────────────────────────────────────────────
echo "--- Symlinks ---"
echo ""
bash "$DOTFILES_DIR/util/scripts/deploy.sh"
echo ""

# ── 4. Oh-my-zsh + config.zsh ────────────────────────────────────────────────
echo "--- zsh ---"
echo ""
bash "$DOTFILES_DIR/util/scripts/install-omz.sh"
echo ""

# ── 5. vim-plug ───────────────────────────────────────────────────────────────
echo "--- vim-plug ---"
echo ""
bash "$DOTFILES_DIR/util/scripts/install-vimplug.sh"
echo ""

# ── 6. Default shell ─────────────────────────────────────────────────────────
ZSH_PATH="$(which zsh)"
if [ "$SHELL" = "$ZSH_PATH" ]; then
  info "Default shell is already zsh"
elif is_wsl; then
  # WSL terminals often ignore chsh and launch bash directly;
  # exec zsh from .bashrc is more reliable
  if grep -qxF 'exec zsh' "$HOME/.bashrc" 2>/dev/null; then
    info "~/.bashrc already launches zsh"
  else
    echo 'exec zsh' >> "$HOME/.bashrc"
    info "Added 'exec zsh' to ~/.bashrc"
  fi
else
  chsh -s "$ZSH_PATH"
  info "Default shell set to zsh"
fi

echo ""
echo -e "${GREEN}=== Setup complete! ===${NC}"
echo "Open a new terminal to start using zsh."
