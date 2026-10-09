# dotfiles

macOS dotfiles managed with GNU Stow. The `macos` branch starts from the
current shared configuration on `main`.

## New machine

Install Homebrew and clone this branch:

```sh
git clone --branch macos --single-branch \
  https://github.com/vetr0s/dotfiles ~/source/repos/dotfiles
cd ~/source/repos/dotfiles
brew bundle
stow --target="$HOME" \
  aerospace bash doom karabiner kitty launchd scripts tmux vim
```

Set Homebrew Bash as the login shell:

```sh
install-bash
```

Open a new terminal before continuing.

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

AeroSpace starts at login. Karabiner maps the right Command key to the
modifier used by AeroSpace. Kitty uses the left Option key as Meta.

## Editors and shell

Doom Emacs is the primary editor. Vim is the terminal fallback. Bash uses
shared history, a small prompt, and a few aliases.

Java editing uses Eclipse JDT LS with Eglot. Install a JDK, then extract a
[JDT LS release](https://download.eclipse.org/justj/?file=jdtls%2Fmilestones)
into `~/.local/share/jdtls`. The executable must exist at
`~/.local/share/jdtls/bin/jdtls`.

Ghostel downloads its native module on first use. Blog publishing loads when
`~/source/blog/publish.el` exists.

## Tags

`tags [project]` creates vi and Emacs tag indexes for C, C++, Go, Python,
Odin, and Zig.

## Updating from main

Bring shared changes across by path. Review changes to `bash/`, `doom/`,
`kitty/`, `scripts/`, `tmux/`, and `vim/`. Copy only changes that apply to
macOS.
