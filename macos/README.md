# macOS configuration

This directory owns configuration and setup that only applies to macOS. The
root setup script deploys these files after the shared configuration.

## Homebrew

The Brewfile contains the small workstation layer used directly by these
dotfiles. It excludes language toolchains, project libraries, and personal
applications.

Install Homebrew using its official instructions. Then run:

```sh
brew bundle --file macos/Brewfile
```

The root setup script does not run Homebrew.

Git and Bash are required for deployment. The Brewfile supplies Neovim 0.12
or newer and the optional tools used directly by these files.

## Setup

Deploy the shared and macOS configuration from the repository root:

```sh
bash setup.sh
```

Install the preferred terminal and editor fonts manually when needed.

macOS ships Bash 3.2. It lacks features used by the shared shell config. Zsh is
the macOS default, but these dotfiles deliberately use Bash on both machines.
The Homebrew package provides a current Bash without adding another shell
config.

Set Homebrew Bash as the login shell after the Brewfile has been installed:

```sh
bash macos/scripts/install-bash.sh
```

Emacs is built separately with
[build-emacs-for-macos](https://github.com/jimeh/build-emacs-for-macos). Build
the daemon launcher after `/Applications/Emacs.app` exists:

```sh
bash macos/scripts/make-emacsclient-app.sh
```

The launchd agent, AeroSpace config, and Karabiner config are linked by the
root setup script. The shell uses Neovim for `$EDITOR` and `$VISUAL`.

Run `emacsctl start` after the first deployment. A later login also loads the
agent through `RunAtLoad`. Use `emacsctl restart` after the agent changes.
Use `emacsctl logs` when the daemon does not become ready.
