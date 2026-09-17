export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="mh"
plugins=(git)
source "$ZSH/oh-my-zsh.sh"

typeset -U path PATH
for dir in "$HOME/.local/bin" "$HOME/.config/emacs/bin" "$HOME/.cargo/bin" "$HOME/go/bin"; do
  [[ -d $dir ]] && path=($dir $path)
done
unset dir

if [[ -d $HOME/.bun ]]; then
  export BUN_INSTALL="$HOME/.bun"
  path=("$BUN_INSTALL/bin" $path)
fi

if [[ -d $HOME/.zvm ]]; then
  export ZVM_INSTALL="$HOME/.zvm/self"
  path=("$HOME/.zvm/bin" "$ZVM_INSTALL" $path)
fi

export EDITOR=emacsclient
export VISUAL=$EDITOR

alias emacs='emacsclient -c -n'
alias e='emacsclient -n'
alias et='emacsclient -t'
alias keys='alias | fzf'
alias lsa='ls -lah'
alias ls='ls --color=auto'

_emacsctl_wait_ready() {
  for attempt in {1..20}; do
    emacsclient -e '(emacs-version)' >/dev/null 2>&1 && return
    sleep 0.5
  done
  print -u2 'Emacs daemon failed to become ready'
  return 1
}

emacsctl() {
  case ${1:-} in
    start)
      systemctl --user daemon-reload &&
        systemctl --user start emacs.service &&
        _emacsctl_wait_ready
      ;;
    stop) systemctl --user stop emacs.service ;;
    restart) systemctl --user restart emacs.service && _emacsctl_wait_ready ;;
    status)
      emacsclient -e '(emacs-version)' >/dev/null 2>&1 &&
        print 'Emacs daemon: running' || print 'Emacs daemon: stopped'
      ;;
    logs) journalctl --user -u emacs.service -f ;;
    *) print 'Usage: emacsctl {start|stop|restart|status|logs}' ;;
  esac
}
