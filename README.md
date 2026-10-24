# dotfiles

macOS dotfiles managed with GNU Stow. The `macos` branch starts from the
shared configuration on `main`.

The desktop uses Karabiner-Elements and kitty.

## New machine

Install Homebrew and clone this branch:

```sh
git clone --branch macos --single-branch \
  https://github.com/vetr0s/dotfiles ~/source/repos/dotfiles
cd ~/source/repos/dotfiles
./setup-macos --dry-run
./setup-macos --install
```

The dry run checks Stow conflicts. The install command runs `brew bundle` and
links each package. Stow refuses to replace an existing file. Move any reported
conflict aside and rerun the command.

Set Homebrew Bash as the login shell:

```sh
install-bash
```

Open a new terminal before continuing.

## Desktop activation

Karabiner-Elements needs its requested Input Monitoring and driver permissions.

## macOS settings

Inspect the current values before changing them:

```sh
macos-desktop-settings status
```

Apply the optional user-level settings explicitly:

```sh
macos-desktop-settings apply
```

The first apply records each key's old value under
`~/.local/state/dotfiles/macos-desktop-settings.tsv`. Later applies only add
keys that are new to the list. The command makes these changes:

| Setting | Value |
| --- | --- |
| Dock auto-hide, delay, and hide speed | on, 0, 0.15s |
| Dock launch animation | off |
| Mission Control animation | 0.1s |
| Rearrange Spaces by recent use | off |
| Key repeat and initial delay | 2 and 15 |
| Window open animation | off |

It restarts the Dock and SystemUIServer. Log out afterwards. The Spaces
setting only applies fully after a new login.

Reduce Motion is not in the script. macOS refuses writes to
`com.apple.universalaccess` from a terminal. Set it in System Settings,
Accessibility, Display.

Restore every saved preference with:

```sh
macos-desktop-settings restore
```

The restore command keeps the consumed backup with a timestamp.

## Emacs

Build Emacs.app with
[build-emacs-for-macos](https://github.com/jimeh/build-emacs-for-macos).
Then install Doom Emacs and start the launchd service:

```sh
git clone --recurse-submodules --depth 1 --shallow-submodules \
  https://github.com/doomemacs/core ~/.config/emacs
~/.config/emacs/bin/doom sync --env
~/.config/emacs/bin/doom doctor
make-emacsclient-app
emacsctl start
```

## Editors and shell

Neovim is the primary editor and the default `$EDITOR`. Its config is built
on its built-in plugin manager. Doom Emacs is kept alongside it. Vim is the
portable terminal fallback. The bashrc follows the layout of Dave Eddy's
bahamas10/dotfiles. The prompt shows the last exit code and the git branch.
History is shared between shells. Machine-specific settings go in
`~/.bashrc.local`.

Java editing uses Eclipse JDT LS in both Neovim and Doom. The Brewfile
installs it as `jdtls`, along with the JDK it runs on.

Ghostel downloads its native module on first use. Blog publishing loads when
`~/source/blog/publish.el` exists.

## Tags

`tags [project]` creates vi and Emacs tag indexes for C, C++, Go, Python,
Odin, and Zig.

## Updating from main

Bring shared changes across by path. Review changes to `bash/`, `doom/`,
`kitty/`, `scripts/`, `tmux/`, and `vim/`. Copy only changes that apply to
macOS.
