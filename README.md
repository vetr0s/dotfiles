# dotfiles

Minimal Arch Linux dotfiles managed with GNU Stow.

The repository configures Doom Emacs, Hyprland, Kitty, tmux, Vim, Zsh, and
their supporting desktop tools. The previous macOS, Bash, Neovim, and
standalone Emacs configuration remains available in Git history under the
`legacy-2026-09-18` tag.

## Why

This revision leans further into simplicity: fewer platforms, fewer custom
scripts, and less configuration to maintain. Arch Linux now runs on my
MacBook, and because that machine is temporary and I do not plan to buy another
MacBook, maintaining a separate macOS setup no longer makes sense.

GNU Stow replaces the custom Bash deployment scripts, while Doom Emacs replaces
the hand-built Emacs configuration. Both already do what I need with a small
amount of configuration, leaving much less for me to own.

## Editors

Doom Emacs is my primary editor for most work on this machine. Vim is the
small, dependable fallback for terminal edits, both locally and over SSH.

## New machine

Starting from an Arch installation with Git:

```sh
git clone https://github.com/vetr0s/dotfiles ~/source/repos/dotfiles
cd ~/source/repos/dotfiles

sudo pacman -Syu --needed - < packages/pkglist.txt

git clone https://github.com/ohmyzsh/ohmyzsh ~/.oh-my-zsh
git clone --recurse-submodules --depth 1 --shallow-submodules \
  https://github.com/doomemacs/core ~/.config/emacs

stow --target="$HOME" doom kitty linux scripts tmux vim zsh
~/.config/emacs/bin/doom sync --env
~/.config/emacs/bin/doom doctor

chsh -s /bin/zsh
systemctl --user daemon-reload
systemctl --user enable --now emacs.service
```

On Apple Silicon, also install the wallpaper fallback:

```sh
sudo pacman -S --needed swaybg
```

Log out and back in after changing the shell. Ghostel downloads its native
module the first time `M-x ghostel` runs. Blog publishing integration activates
when `~/source/blog/publish.el` exists.

## Packages

`packages/pkglist.txt` is a curated list, not a snapshot of everything
installed. Keep packages that belong on a fresh workstation; leave out
dependencies, installer and hardware support, temporary diagnostics, and
applications no longer in use.

Review explicitly installed repository packages that are not already listed:

```sh
comm -23 \
  <(pacman -Qqen | sort) \
  <(sort packages/pkglist.txt) \
  | fzf --multi \
      --header='Tab selects; Enter finishes' \
      --preview='pacman -Qi {}' \
      --preview-window='right,60%,wrap' \
  > /tmp/pkglist-additions.txt
```

Edit the selection, apply it, and inspect the result:

```sh
cat /tmp/pkglist-additions.txt >> packages/pkglist.txt
sort -uo packages/pkglist.txt packages/pkglist.txt
rm /tmp/pkglist-additions.txt
git diff -- packages/pkglist.txt
```

## Tags

`tags [project]` creates vi and Emacs tag indexes for C, C++, Go, Python, Odin,
and Zig.
