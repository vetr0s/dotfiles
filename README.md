# dotfiles

The purpose of this repository is to store all configuration of any essential developer tools that I use.

## Usage

### Installation

1. Clone the GitHub repository to where ever you like
2. Run the helper `deploy.sh` & `install-vimplug.sh` scripts

### deploy.sh

This script essentially symlinks `.vimrc`, `.emacs.d/`, `.tmux.conf`, & `alacritty/` to their respective
locations where they are exposed to the program itself. If the directory does not exist, for instance
if you do not have alacritty or tmux installed. Currently, the `deploy.sh` script does not create these
directories for you so either they will be created automatically in your `$HOME/.config/` directory or
you can create them yourself.

For example, from within the dotfiles directory:

```sh
mkdir -p $HOME/.config/tmux
./deploy.sh
```

Then the script will symlink the tmux configuration file to that location.

### Vim

Currently, for simple plugins, my `.vimrc` uses [vim-plug](https://github.com/junegunn/vim-plug). To make installing vim-plug
easier on a new machine, consider using the `install-vimplug.sh` script, which just runs the curl command found on the vim-plug
repository. Once installed from within vim:

```txt
:PlugInstall
```

To install all the plugins listed in the `.vimrc` file.
