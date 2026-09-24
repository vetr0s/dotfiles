# dotfiles

Void Linux and i3 dotfiles for my main development machine, managed with GNU Stow.
The `arch-hyprland` branch keeps the Arch Linux, Hyprland, Waybar, and systemd
setup for my other machines. Older macOS and editor configurations are in the
`legacy-2026-09-18` tag.

## New machine

Starting from a Void installation with Git:

```sh
git clone https://github.com/vetr0s/dotfiles ~/source/repos/dotfiles
cd ~/source/repos/dotfiles

sudo xbps-install -Su
xargs -r sudo xbps-install -S < packages/pkglist.txt

git clone --recurse-submodules --depth 1 --shallow-submodules \
  https://github.com/doomemacs/core ~/.config/emacs

stow --target="$HOME" bash doom i3 kitty scripts tmux vim
~/.config/emacs/bin/doom sync --env
~/.config/emacs/bin/doom doctor

sudo ln -s /etc/sv/dbus /var/service/
sudo ln -s /etc/sv/NetworkManager /var/service/
sudo ln -s /etc/sv/lightdm /var/service/
sudo install -Dm755 runit/emacs/run /etc/sv/emacs/run
sudo ln -s /etc/sv/emacs /var/service/
```

The Emacs service runs as `vetr0s`; change the username in `runit/emacs/run` on
another account. Log out and back in after changing the shell with
`chsh -s /bin/bash`. Ghostel downloads its native module on first use. Blog
publishing loads when `~/source/blog/publish.el` exists.

`packages/pkglist.txt` is a curated workstation list, not a full inventory.
Keep hardware drivers and one-off tools out of it. The i3 and i3status files
come from this machine's working setup.

## Editors and shell

Doom Emacs is the primary editor; Vim is the fallback for terminals and SSH.
Bash uses shared/searchable history, a small prompt, and a few aliases.
Java editing uses Eclipse JDT LS with Eglot. Extract a
[JDT LS release](https://download.eclipse.org/justj/?file=jdtls%2Fmilestones)
into `~/.local/share/jdtls` so `~/.local/share/jdtls/bin/jdtls` exists.

## Tags

`tags [project]` creates vi and Emacs tag indexes for C, C++, Go, Python,
Odin, and Zig.
