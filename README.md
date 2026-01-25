# dotfiles

The purpose of this repository is to store all configuration of any essential developer tools that I use.

## Usage

### Installation

1. Clone the GitHub repository to where ever you like

```sh
git clone --depth=1 https://github.com/nathantebbs/dotfiles
```

2. Run the helper `deploy.sh` & `install-vimplug.sh` scripts

### deploy.sh

This script essentially symlinks `.vimrc`, `.emacs.d/`, `.tmux.conf`, & `alacritty/` to their respective
locations where they are exposed to the program itself.

### Vim

Currently, for simple plugins, my `.vimrc` uses [vim-plug](https://github.com/junegunn/vim-plug). To make installing vim-plug
easier on a new machine, consider using the `install-vimplug.sh` script, which just runs the curl command found on the vim-plug
repository. Once installed from within vim:

```txt
:PlugInstall
```

To install all the plugins listed in the `.vimrc` file.

## zsh

I use zsh, and [oh-my-zsh](https://ohmyz.sh/) for theme and plugins. To automate the process I created the `install-omz.sh` script,
which runs the installer command without taking over the terminal & sources the user configuration file `config.zsh` at the end
of `~/.zshrc`.
