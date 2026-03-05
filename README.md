# dotfiles

The purpose of this repository is to store all configuration of any essential developer tools that I use.

## Dependencies

`setup.sh` installs missing dependencies automatically via `apt` (Linux) or `brew` (macOS).

| Package | Purpose |
|---------|---------|
| `git` | Version control |
| `curl` | Script downloads |
| `zsh` | Shell |
| `neovim` | Primary editor (desktop/server) |
| `emacs` | Secondary editor |
| `ripgrep` | Telescope live grep |
| `fzf` | Fuzzy finder (vim + shell) |
| `make` | Build telescope-fzf-native |

Desktop Linux (bare metal only — skipped on WSL/macOS):

| Package | Purpose |
|---------|---------|
| `hyprland` | Wayland compositor |
| `waybar` | Status bar |
| `rofi` | App launcher |
| `kitty` | Terminal emulator |
| `hypridle` + `hyprlock` | Idle / lock screen |

## Usage

### Installation

1. Clone the repository

```sh
git clone --depth=1 https://github.com/nathantebbs/dotfiles
cd dotfiles
```

2. Run setup (installs dependencies, fonts, symlinks, zsh)

```sh
bash setup.sh
```

> **macOS:** [Homebrew](https://brew.sh) must be installed before running `setup.sh`.

### Individual scripts

If you only need part of the setup:

```sh
bash util/scripts/deploy.sh        # symlinks only
bash util/scripts/install-fonts.sh # fonts only
bash util/scripts/install-omz.sh   # oh-my-zsh + config.zsh
bash util/scripts/install-vimplug.sh
```

### deploy.sh

Located at `util/scripts/deploy.sh`, this script creates symlinks for all configurations to their expected locations. It safely backs up any existing files before creating symlinks.

Cross-platform:

| Config | Target |
|--------|--------|
| `.emacs.d/` | `~/.emacs.d` |
| `.vimrc` | `~/.vimrc` |
| `tmux/` | `~/.config/tmux` |
| `nvim/` | `~/.config/nvim` |
| `kitty/` | `~/.config/kitty` |

Linux only (Wayland/Hyprland stack — skipped on macOS):

| Config | Target |
|--------|--------|
| `waybar/` | `~/.config/waybar` |
| `rofi/` | `~/.config/rofi` |
| `hypr/` | `~/.config/hypr` |

### install-fonts.sh

Place font files (`.ttf`/`.otf`) in the `fonts/` directory at the repo root, then run:

```sh
bash util/scripts/install-fonts.sh
```

Installs fonts to `~/.local/share/fonts` (Linux) or `~/Library/Fonts` (macOS) and refreshes the font cache. Required for configs that use **Zenbones Brainy**.

## Editors

### Vim

My `.vimrc` uses [vim-plug](https://github.com/junegunn/vim-plug) for plugin management. To install vim-plug on a new machine:

```sh
bash util/scripts/install-vimplug.sh
```

Then from within vim:

```txt
:PlugInstall
```

**Plugins:** fzf, vim-surround, lightline, vim-polyglot, vim-todo-highlight, undotree

### Neovim

`nvim/init.lua` is a desktop-only Neovim config using [lazy.nvim](https://github.com/folke/lazy.nvim). lazy.nvim is bootstrapped automatically on first launch — no manual install needed.

**Plugins:** Telescope, vim-surround, lightline, nvim-autopairs, vim-polyglot, todo-comments, presenting.nvim, undotree, vim-colors-modus, typst.vim

**Key bindings:**

| Binding | Action |
|---------|--------|
| `C-x f` | Find files (Telescope) |
| `C-x b` | Buffers (Telescope) |
| `C-x l` | Live grep (Telescope) |
| `C-x m` | Keymaps (Telescope) |
| `C-c C-u` | Toggle undotree |
| `C-c C-e` | Open netrw |
| `C-c C-p i` | Lazy sync |
| `C-c C-p c` | Lazy clean |

### Emacs

`.emacs.d/` is built on [minimal-emacs.d](https://github.com/jamescherti/minimal-emacs.d) and uses [Elpaca](https://github.com/progfolio/elpaca) as the package manager.

Notable packages: Evil (vim emulation), evil-collection, evil-surround, Helm, Corfu + Cape (completion), Org mode, ox-reveal (Reveal.js export), Haskell, Zig, Odin language support, Magit, YASnippet, Apheleia (formatting), easysession, mu4e (optional email).

Font: Zenbones Brainy — see [font installation](#font).

## Terminal

### Kitty

`kitty/kitty.conf` configures the [Kitty](https://sw.kovidgoyal.net/kitty/) terminal emulator.

- Font: Zenbones Brainy, 16pt
- Background opacity: 0.92
- Cursor: block

## zsh

I use zsh with [oh-my-zsh](https://ohmyz.sh/) for theme and plugins. To automate installation:

```sh
bash util/scripts/install-omz.sh
```

This installs oh-my-zsh and sources `config.zsh` at the end of `~/.zshrc`.

**`config.zsh` provides:**

- Aliases: `docker` (sudo wrapper), `emacs-kill`, `reboot`, `vim` → nvim, `keys` (fzf alias search), `spotify`
- `emacsctl` — manage the Emacs daemon:
  ```sh
  emacsctl start    # launch daemon
  emacsctl stop     # kill daemon
  emacsctl restart  # kill and relaunch
  emacsctl status   # check if running
  ```
- OS-specific `$EDITOR` (nvim path varies between macOS and Linux)
- PATH: GHCup (`~/.ghcup/bin`) and `~/.local/bin`

## Desktop

### Hyprland

`hypr/` contains configuration for [Hyprland](https://hyprland.org/):

- `hyprland.conf` — main compositor config
- `hyprpaper.conf` — wallpaper config
- `hyprlock.conf` — lock screen config

### Waybar

`waybar/` contains a Waybar status bar configuration for use with Hyprland. See [`waybar/README.md`](waybar/README.md) for screenshots and setup details.

Recommended font: [JetbrainsMono Nerd Font](https://github.com/ryanoasis/nerd-fonts)

### Rofi

`rofi/config.rasi` provides an application launcher configuration.

## tmux

`tmux/tmux.conf` is linked to `~/.config/tmux` by the deploy script.

## Font

Several configs (Kitty, Emacs) use **Zenbones Brainy**. Place the font files (`.ttf`/`.otf`) in `fonts/` at the repo root and run `util/scripts/install-fonts.sh` to install them automatically.
