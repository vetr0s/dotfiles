# dotfiles

Minimal Arch Linux dotfiles managed with GNU Stow.

## New machine

Starting from an Arch installation with Git:

```sh
git clone https://github.com/vetr0s/dotfiles ~/source/repos/dotfiles
cd ~/source/repos/dotfiles

profile=generic # use asahi on Apple Silicon
awk '$1 == "official" { print $2 }' \
  packages/linux/packages.tsv "packages/linux/packages-$profile.tsv" \
  | xargs sudo pacman -S --needed
awk '$1 == "aur" { print $2 }' \
  packages/linux/packages.tsv "packages/linux/packages-$profile.tsv" \
  | xargs -r yay -S --needed

git clone https://github.com/ohmyzsh/ohmyzsh ~/.oh-my-zsh
git clone --recurse-submodules --depth 1 --shallow-submodules \
  https://github.com/doomemacs/core ~/.config/emacs

stow --target="$HOME" doom kitty linux scripts tmux zsh
~/.config/emacs/bin/doom sync --env
~/.config/emacs/bin/doom doctor

chsh -s /bin/zsh
systemctl --user daemon-reload
systemctl --user enable --now emacs.service
```

Log out and back in after changing the shell. Ghostel downloads its native
module the first time `M-x ghostel` runs.

## Tags

`tags [project]` creates vi and Emacs tag indexes for C, C++, Go, Python, Odin,
and Zig.
