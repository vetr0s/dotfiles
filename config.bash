# -n is what frees the terminal. The old "&disown" backgrounded the alias
# itself, which also threw away emacsclient's errors when the daemon was down.
# No -a "": that would start a daemon outside the service manager. Run
# emacsctl start if these report that no socket exists.
alias emacs='emacsclient -c -n'
alias e='emacsclient -n'
alias et='emacsclient -t'
alias keys="alias | fzf"
alias lsa="ls -lah"

# Polls emacsclient until the daemon answers, for the restart path on either OS.
_emacsctl_wait_ready() {
  local attempt
  for attempt in {1..20}; do
    command emacsclient -e "(emacs-version)" >/dev/null 2>&1 && return
    sleep 0.5
  done
  echo "Emacs daemon failed to become ready" >&2
  return 1
}

_emacsctl_status() {
  command emacsclient -e "(emacs-version)" >/dev/null 2>&1 \
    && echo "Emacs daemon: running" \
    || echo "Emacs daemon: stopped"
}

# The omz git plugin by hand, cut to what I actually type. The names are
# upstream's, so the muscle memory carries over from zsh.
alias g='git'
alias gst='git status'
alias gss='git status --short'
alias ga='git add'
alias gaa='git add --all'
alias gc='git commit -v'
alias gcmsg='git commit -m'
alias gcam='git commit -a -m'
alias gco='git checkout'
alias gcb='git checkout -b'
alias gsw='git switch'
alias gswc='git switch -c'
alias gd='git diff'
alias gds='git diff --staged'
alias gb='git branch'
alias gl='git pull'
alias gp='git push'
alias glo='git log --oneline --decorate'
alias glog='git log --oneline --decorate --graph'
alias grs='git restore'
alias grst='git restore --staged'
alias gsta='git stash push'
alias gstp='git stash pop'
alias gstl='git stash list'

# omz's amend aliases. `!=` is one of the few things history expansion leaves
# alone, and a trailing `!` is literal, so these are safe in an interactive shell.
alias gc!='git commit -v --amend'
alias gca!='git commit -v -a --amend'

# PATH. Each entry is guarded so a machine missing the toolchain doesn't break
# its shell, and so this file stays portable between macOS and Linux.
[ -d "$HOME/.local/bin" ] && export PATH="$HOME/.local/bin:$PATH"
[ -d "$HOME/.cargo/bin" ] && export PATH="$HOME/.cargo/bin:$PATH"
[ -d "$HOME/go/bin" ]     && export PATH="$HOME/go/bin:$PATH"

# ~/.bun/_bun is a zsh compdef file with no bash equivalent, so only the
# binary comes across.
if [ -d "$HOME/.bun" ]; then
  export BUN_INSTALL="$HOME/.bun"
  export PATH="$BUN_INSTALL/bin:$PATH"
fi

case "$OSTYPE" in
  darwin*) . "$DOTFILES_DIR/macos/config.bash" ;;
  linux*) . "$DOTFILES_DIR/linux/config.bash" ;;
esac
