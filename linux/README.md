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

The wallpaper config expects `~/Pictures/mountain.jpg`. Change the tracked path
in `linux/hypr/hyprpaper.conf` when the workstation wallpaper changes.

## Session

Hyprland starts Waybar, Hyprpaper, Hypridle, Hyprlauncher, Dunst, the
NetworkManager applet, and Hyprpolkitagent.

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
