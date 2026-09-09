# Emacs runs under launchd. Manage the job instead of its child process.
emacsctl() {
  local label="dev.nathantebbs.emacs"
  local target="gui/$(id -u)/$label"

  case "${1:-}" in
    start)
      if ! launchctl bootstrap "gui/$(id -u)" \
        "$HOME/Library/LaunchAgents/$label.plist" 2>/dev/null; then
        launchctl kickstart "$target"
      fi
      _emacsctl_wait_ready ;;
    stop) launchctl bootout "$target" ;;
    restart)
      launchctl print "$target" >/dev/null 2>&1 && launchctl bootout "$target"
      sleep 1
      launchctl bootstrap "gui/$(id -u)" \
        "$HOME/Library/LaunchAgents/$label.plist"
      _emacsctl_wait_ready ;;
    status) _emacsctl_status ;;
    logs)
      log show --last 1h --style compact \
        --predicate 'process == "Emacs"' ;;
    *) echo "Usage: emacsctl {start|stop|restart|status|logs}" ;;
  esac
}

export EDITOR="nvim"
export VISUAL="$EDITOR"
export CLICOLOR=1
export LSCOLORS="GxFxBxdxCxDxdxabagacad"

# /etc/paths.d/homebrew appends, which lands Homebrew after /bin. The system
# bash 3.2 then shadows the 5.x the Brewfile installs. Prepending fixes that.
[ -d "/opt/homebrew/bin" ] \
  && export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:$PATH"

[ -d "/Applications/Emacs.app/Contents/MacOS/bin" ] \
  && export PATH="/Applications/Emacs.app/Contents/MacOS/bin:$PATH"
