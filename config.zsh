alias docker="sudo docker"
alias emacs="emacsclient -c &disown"
alias emacs-status='emacsclient -e "(emacs-version)"'
alias emacs-kill='emacsclient -e "(kill-emacs)"'
alias reboot="sudo shutdown -r now"
alias vim="nvim"

emacsctl() {
  case "$1" in
    start)
      command emacs --daemon ;;
    stop)
      command emacsclient -e "(kill-emacs)" >/dev/null 2>&1 ;;
    restart)
      command emacsclient -e "(kill-emacs)" >/dev/null 2>&1 || true
      command emacs --daemon ;;
    status)
      command emacsclient -e "(emacs-version)" >/dev/null 2>&1 \
        && echo "Emacs daemon: running" \
        || echo "Emacs daemon: stopped" ;;
    *)
      echo "Usage: emacsctl {start|stop|restart|status}" ;;
  esac
}

export PATH="$HOME/.ghcup/bin:$PATH"
