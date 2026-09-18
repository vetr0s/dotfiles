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


# NOTE: for some reason not having this set makes the below configuration null
export GROFF_NO_SGR=1

# Colorized man pages
# annotated by dave eddy (@yousuckatprogramming)
# explained - https://youtu.be/D0sG2fj0G4Y
# borrowed heavily from https://grml.org
# Begin blinking text mode
# I just use bold red here since my terminal has blinking disabled
export LESS_TERMCAP_mb=$'\e[1;31m'

# Begin bold text mode
export LESS_TERMCAP_md=$'\e[1;31m'

# End all special formatting started by mb/md/etc.
export LESS_TERMCAP_me=$'\e[0m'

# End standout mode
export LESS_TERMCAP_se=$'\e[0m'

# Begin standout mode
# search results - bold, yellow foreground, blue background.
export LESS_TERMCAP_so=$'\e[1;33;44m'

# End underline mode
export LESS_TERMCAP_ue=$'\e[0m'

# Begin underline mode
# underline and bold green
export LESS_TERMCAP_us=$'\e[4;1;32m'

# Begin reverse-video mode
export LESS_TERMCAP_mr=$'\e[7m'

# Begin dim/half-bright mode
export LESS_TERMCAP_mh=$'\e[2m'

# Begin subscript mode
# (probably isn't supported)
export LESS_TERMCAP_ZN=$'\e[74m'

# End subscript mode
# (probably isn't supported)
export LESS_TERMCAP_ZV=$'\e[75m'

# Begin superscript mode
# (probably isn't supported)
export LESS_TERMCAP_ZO=$'\e[73m'

# End superscript mode
# (probably isn't supported)
export LESS_TERMCAP_ZW=$'\e[75m'

# Finally wire up `man` to use `less`
# this is usually the default but let's just be sure
export MANPAGER='less'
