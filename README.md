# dotfiles

My configuration for macOS and an opinionated Arch Linux + Hyprland desktop.
Shared files live at the root. Platform integration lives under
[`macos/`](macos/) and [`linux/`](linux/).

The setup script deploys configuration. It does not install packages or change
system services. The Linux package checker reports missing Arch packages and
prints the command to install them. The macOS side has a small optional
[`Brewfile`](macos/Brewfile), but I keep system setup explicit.

## Requirements

Deployment needs Git and Bash. The editor configurations require Emacs 31 or
newer and Neovim 0.12 or newer. The tmux configuration requires tmux 3.1 or
newer. Optional editor and platform tools are listed in the platform guides.

## Deploy

```sh
git clone --depth=1 https://github.com/vetr0s/dotfiles
cd dotfiles
bash setup.sh
```

`setup.sh` detects the platform and links the matching files into place. It
moves an existing target to a timestamped backup. Later runs leave correct
links alone.

Preview the changes first:

```sh
bash setup.sh --dry-run
```

The platform can also be selected for testing:

```sh
bash setup.sh --platform macos --dry-run
bash setup.sh --platform linux --dry-run
```

Package installation and host services stay outside the root setup script.
The platform READMEs define that boundary:

- [macOS setup and services](macos/README.md)
- [Linux setup](linux/README.md)

## What I use

Emacs is my primary GUI editor. I run it as a daemon so `emacsclient` can open
frames without starting another process. Its configuration has a separate
[README](.emacs.d/README.md).

Neovim owns `$EDITOR` and `$VISUAL` for terminal work. Vim remains the small
fallback. Both use `<Space>` as the leader and share the bindings I use most.

Kitty is the terminal. AeroSpace handles tiling on macOS. Karabiner maps the
right diamond key to the modifier AeroSpace uses. Bash is the login shell and
tmux remains available for remote sessions.

The repository also carries my Git configuration and C formatting rules.

## Layout

| Path | Contents |
| --- | --- |
| `.emacs.d/`, `nvim/`, `.vimrc` | Editor configuration |
| `bashrc`, `bash_profile`, `config.bash` | Shell configuration |
| `kitty/`, `tmux/` | Terminal configuration |
| `gitconfig`, `clang-format` | Tool configuration |
| `LICENSES/` | Third-party license texts |
| `macos/` | Homebrew, launchd, AeroSpace, and Karabiner |
| `linux/` | Arch packages, Hyprland, Waybar, Dunst, and Linux shell integration |
| `util/links.tsv` | Shared deployment manifest |

## Verify

Run every available regression suite from the repository root:

```sh
tests/run.sh
```

The runner tests shell helpers and deployment invariants. It also runs the
Emacs and Neovim suites when those programs are installed.

## Optional helpers

These are separate from deployment:

```sh
bash util/scripts/tags.sh [project]
bash util/scripts/install-ols.sh
bash util/scripts/install-vimplug.sh
bash macos/scripts/install-bash.sh
bash macos/scripts/make-emacsclient-app.sh
```

`tags.sh` indexes a project for goto-definition. It is what Emacs uses, and
what Neovim falls back to outside Odin. It writes `tags` for Neovim, which
finds it through the default `./tags;`, and `.tags` for Emacs, which
`rc-programming` visits when a buffer opens. One helper invocation runs
universal-ctags twice to create both formats. The two editors use the same
source index. C, C++, Go and Python use built-in parsers. Odin and Zig use
regex definitions because universal-ctags ships neither. Rerun the helper when
the index goes stale.

On Arch Linux, report missing workstation packages with:

```sh
bash linux/scripts/check-packages.sh
```

Zenbones Brainy is a manual machine preference. Arch installs the Nerd Font
symbols used by Waybar through the package manifest.

`install-ols.sh` builds the Odin language server and `odinfmt` from source.
They need Git and the `odin` compiler. The source checkout goes to
`~/source/third_party/ols`. The script builds the tested commit in a temporary
worktree. It publishes both binaries as one versioned unit under
`~/.local/bin`. Override the locations with `OLS_SRC_DIR` and `OLS_BIN_DIR`.
`OLS_REVISION` and `OLS_ODIN_VERSION` record the tested source and compiler
revisions. The script reuses a complete release for the same pins. Remove that
release directory to force a rebuild. Override both pins together when testing
an upgrade. Neovim enables `ols` only when it is on `PATH`. Both editors skip
Odin formatting when `odinfmt` is unavailable.

## Emacs daemon

The `emacs`, `e`, and `et` aliases connect to the managed daemon. Use
`emacsctl start`, `emacsctl stop`, `emacsctl restart`, and `emacsctl status`
on either platform. `emacsctl logs` reads the platform service log. The macOS
and Linux guides cover the initial service setup.
