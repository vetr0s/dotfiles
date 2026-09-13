# Login shells load the shared interactive configuration.
[ -f "$HOME/.bashrc" ] && . "$HOME/.bashrc"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
