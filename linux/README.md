# Arch Linux and Hyprland

This directory defines my Arch Linux desktop. It assumes Hyprland,
Hyprlauncher, Waybar, Dunst, PipeWire, NetworkManager, Kitty, and Dolphin.

## Requirements

Install Git and Bash before deployment. Install Emacs 31 or newer with
`emacsclient` when using the service. Install Neovim 0.12 or newer for the
Neovim configuration. Tmux must be 3.1 or newer.

## Packages

Deployment never runs `sudo`, `pacman`, or `yay`. Check the package manifest:

```sh
bash linux/scripts/check-packages.sh
```

The checker reports missing packages and prints the commands that would install
them. Official packages use `pacman`. Future AUR entries use an existing `yay`
installation. Every current package comes from an official Arch repository.
The common manifest includes Symbols Nerd Font Mono for the configured icons.
The checker also selects `packages-asahi.tsv` on Apple Silicon hardware and
`packages-generic.tsv` elsewhere.

## Deploy

Run these commands from the repository root:

```sh
bash setup.sh --platform linux --dry-run
bash setup.sh --platform linux
```

Deployment links the shared configuration and these Linux directories:

- `~/.config/hypr`
- `~/.config/waybar`
- `~/.config/dunst`
- `~/.config/systemd/user/emacs.service`

The deployer moves each existing target to a timestamped backup. It leaves an
existing correct link alone.

The wallpaper startup helper uses Swaybg on Apple Silicon hardware, where
Hyprpaper 0.8.4 crashes, and Hyprpaper elsewhere. Both configurations expect
`~/Pictures/mountain.jpg`; change the tracked paths in `linux/hypr/` when the
workstation wallpaper changes.

Bootstrap Emacs packages before enabling its daemon:

```sh
bash util/scripts/bootstrap-emacs.sh
```

## Session

Hyprland starts Waybar, the hardware-selected wallpaper daemon, Hypridle,
Hyprlauncher, Dunst, the
NetworkManager applet, and Hyprpolkitagent.

The Lua config uses hy3 when its hyprpm build is present and falls back to
`dwindle` otherwise. Hyprland 0.56.1 is not listed in hy3's current hyprpm
commit pins, so install the verified 0.56.0.1 plugin revision explicitly on
machines running that release:

```sh
hyprpm add https://github.com/outfoxxed/hy3.git 42b7ed8fd9aefd3f36e5f617afd5071245c67853
hyprpm enable hy3
```

Do not run hyprpm with `sudo`; it invokes privilege elevation itself when it
updates `/var/cache/hyprpm`. The config loads the resulting plugin directly on
Hyprland startup. `Super+H/J/K/L` changes focus, `Super+Ctrl+H/J/K/L` moves a
window, `Super+G` creates or removes a split group, `Super+T` toggles tabbing,
and `Super+U/I` raises or lowers focus through nested groups.

Check the active configuration after an edit:

```sh
Hyprland --verify-config --config linux/hypr/hyprland.lua
hyprctl reload
hyprctl configerrors
```

## Bindings

| Binding | Action |
| --- | --- |
| `Super+Return` | Open Kitty |
| `Super+R` | Open Hyprlauncher |
| `Super+E` | Open Dolphin |
| `Super+Q` | Close the active window |
| `Super+H/J/K/L` | Move focus |
| `Super+Shift+L` | Lock the session |
| `Super+M` | Open Hyprshutdown |
| `Print` | Capture every output |
| `Super+Print` | Capture a selected region |

## Emacs daemon

Arch provides an Emacs user service. Enable it once if needed:

```sh
systemctl --user daemon-reload
systemctl --user enable --now emacs.service
```

The Bash function `emacsctl` starts, stops, restarts, checks, and follows logs
for that service.

`emacsctl start` reloads the user service definitions before starting Emacs.
Both `start` and `restart` wait for the server socket before returning.
