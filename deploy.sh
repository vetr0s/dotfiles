#!/bin/sh

##############################################################################
#          File: deploy.sh
#        Author: Nathan Tebbs
#       Updated: 2026-01-22
#   Description: Setup symlinks for emacs, vim, tmux, and alacritty 
#                configurations.
##############################################################################


set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to create symlink safely
create_symlink() {
    local source="$1"
    local target="$2"
    local name="$3"

    # Check if source exists
    if [ ! -e "$source" ]; then
        echo "${RED}[ERROR]${NC} Source not found: $source"
        return 1
    fi

    # If target already exists
    if [ -e "$target" ] || [ -L "$target" ]; then
        # If it's already a symlink pointing to the right place
        if [ -L "$target" ] && [ "$(readlink "$target")" = "$source" ]; then
            echo -e "${GREEN}[OK]${NC} $name already linked correctly"
            return 0
        fi

        # Otherwise, backup the existing file/directory
        backup="${target}.backup.$(date +%Y%m%d_%H%M%S)"
        echo "${YELLOW}[INFO]${NC} Backing up existing $name to $backup"
        mv "$target" "$backup"
    fi

    # Create the symlink
    ln -s "$source" "$target"
    echo "${GREEN}[OK]${NC} Linked $name"
}

echo "Setting up dotfiles symlinks..."
echo ""

# TODO: create symlink for i3 configuration

create_symlink "$DOTFILES_DIR/.emacs.d" "$HOME/.emacs.d" "emacs"
create_symlink "$DOTFILES_DIR/.vimrc" "$HOME/.vimrc" "vim"
create_symlink "$DOTFILES_DIR/.tmux.conf" "$HOME/.config/tmux/tmux.conf" "tmux"
create_symlink "$DOTFILES_DIR/alacritty" "$HOME/.config/alacritty" "alacritty"

echo ""
echo "${GREEN}[OK]${NC} Symlink deployment complete!"
