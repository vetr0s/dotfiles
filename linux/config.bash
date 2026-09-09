export EDITOR="nvim"
export VISUAL="$EDITOR"
alias ls='ls --color=auto'

emacsctl() {
  case "${1:-}" in
    start)
      systemctl --user daemon-reload \
        && systemctl --user start emacs.service \
        && _emacsctl_wait_ready ;;
    stop) systemctl --user stop emacs.service ;;
    restart) systemctl --user restart emacs.service && _emacsctl_wait_ready ;;
    status) _emacsctl_status ;;
    logs) journalctl --user -u emacs.service -f ;;
    *) echo "Usage: emacsctl {start|stop|restart|status|logs}" ;;
  esac
}
