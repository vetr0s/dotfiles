# Interactive bash.
#
# The split from the zsh setup carries over: this file is the shell-specific
# half (history, shopt, keymap, prompt) and config.bash is the shared Bash half
# (aliases, functions, PATH).

# Non-interactive shells want none of this. scp and rsync break if a
# startup file writes to stdout, so bail before anything can.
case $- in
  *i*) ;;
  *) return ;;
esac

# History. bash defaults to 500 lines and last-window-wins on exit; the
# append plus the `history -a` in __prompt is what makes two terminals share
# a history.
HISTSIZE=100000
HISTFILESIZE=100000
HISTCONTROL=ignoreboth:erasedups
HISTIGNORE='ls:ll:cd:pwd:exit:clear:history'
HISTTIMEFORMAT='%F %T '
shopt -s histappend cmdhist

shopt -s checkwinsize          # recompute LINES/COLUMNS after a resize
shopt -s globstar              # ** recurses
shopt -s autocd                # a bare directory name cds into it
shopt -s cdspell dirspell      # fix small typos in path arguments

# Emacs keys, matching the editor. bash defaults to this; the line is here
# so the keymap is stated rather than inherited.
set -o emacs

# ~/.bashrc is a symlink into the repo, so BASH_SOURCE points at the link.
# Resolve it and config.bash loads no matter where the repo is cloned.
_rc="${BASH_SOURCE[0]}"
while [ -L "$_rc" ]; do
  _target="$(readlink "$_rc")"
  case "$_target" in
    /*) _rc="$_target" ;;
    *)  _rc="$(dirname "$_rc")/$_target" ;;
  esac
done
DOTFILES_DIR="$(cd -P "$(dirname "$_rc")" && pwd)"
unset _rc _target

. "$DOTFILES_DIR/config.bash"

# Prompt. Two lines: identity, location and state on the first, the command on
# the second. The command always starts at column three, however deep the path.
#
# Bash builtins throughout bar one `git status` and one `jobs` per prompt.
# \[ \] wraps every escape so bash counts the printed width and long lines wrap
# correctly. Branch and venv names have \ ` $ stripped, because bash expands
# PS1 again on every draw and a branch name is not trusted input.

# Command duration, measured with SECONDS so it costs no fork. The DEBUG trap
# records once per command line, armed by the previous prompt, so the time
# spent typing a command is not counted as time spent running it.
__prompt_timer() {
  if [ -n "$__prompt_armed" ]; then
    __prompt_t0=$SECONDS
    unset __prompt_armed
  fi
}
trap '__prompt_timer' DEBUG

# Branch, worktree state and upstream divergence from one porcelain v2 call.
# Writes the git_* variables __prompt declares local; returns 1 outside a repo.
__prompt_git() {
  local out line ab oid d=$PWD staged= dirty= untracked= conflict=

  # `git status` is a process exec and costs ~10ms, all of it wasted outside a
  # repo. Walking up for .git first is builtins only. GIT_DIR means skip it.
  if [ -z "$GIT_DIR" ]; then
    while [ ! -e "$d/.git" ]; do
      [ -z "$d" ] && return 1
      d=${d%/*}
    done
  fi

  out=$(git status --porcelain=v2 --branch 2>/dev/null) || return 1
  git_head= git_flags= git_ab=
  while IFS= read -r line; do
    case $line in
      '# branch.oid '*)  oid=${line#'# branch.oid '} ;;
      '# branch.head '*) git_head=${line#'# branch.head '} ;;
      '# branch.ab '*)
        # "+1 -2", either half zero when there is nothing to report.
        ab=${line#'# branch.ab '}
        [ "${ab%% *}" != +0 ] && git_ab+=" ↑${ab%%' '*}"
        [ "${ab##* }" != -0 ] && git_ab+=" ↓${ab##*-}" ;;
      # "1 XY ..." and "2 XY ...": X is the index, Y is the worktree.
      '1 '*|'2 '*)
        [ "${line:2:1}" != . ] && staged=1
        [ "${line:3:1}" != . ] && dirty=1 ;;
      'u '*) conflict=1 ;;
      '?'*)  untracked=1 ;;
    esac
  done <<<"$out"

  git_ab=${git_ab//+/}
  [ -n "$staged" ]    && git_flags+=+
  [ -n "$dirty" ]     && git_flags+='*'
  [ -n "$untracked" ] && git_flags+=?
  [ -n "$conflict" ]  && git_flags+=!

  [ "$git_head" = '(detached)' ] && git_head="@${oid:0:7}"
  git_head=${git_head//[\\\`\$]/}
  return 0
}

# SECONDS has no better resolution, and anything under five seconds is noise,
# so the shortest this prints is 5s.
__prompt_elapsed() {
  local s=$1
  if   [ "$s" -lt 60 ];   then REPLY="${s}s"
  elif [ "$s" -lt 3600 ]; then REPLY="$((s / 60))m$((s % 60))s"
  else                         REPLY="$((s / 3600))h$((s / 60 % 60))m"
  fi
}

# `\$' expands to # for root and $ for anyone else. Only the unprivileged half
# becomes a lambda; the root warning is the whole point of that character and
# is not worth trading away. Fixed at startup, since the euid cannot change
# under a running shell.
__prompt_char=λ
[ "$EUID" = 0 ] && __prompt_char='#'

__prompt() {
  local status=$1
  history -a

  local user='\[\e[1;36m\]' at='\[\e[1;33m\]'  host='\[\e[1;35m\]'
  local brk='\[\e[1;32m\]'  dir='\[\e[1;34m\]' repo='\[\e[1;32m\]'
  local flag='\[\e[1;33m\]' ab='\[\e[1;36m\]'  bad='\[\e[1;31m\]'
  local dim='\[\e[90m\]'    off='\[\e[0m\]'

  # A shell on another machine is worth noticing before running rm.
  [ -n "$SSH_CONNECTION" ] && host=$bad

  local line="$user\\u$at@$host\\h$brk [$dir\\w$brk]"

  local git_head git_flags git_ab
  __prompt_git &&
    line+=" $repo($git_head$flag$git_flags$ab$git_ab$repo)"

  local venv=${VIRTUAL_ENV##*/}
  [ -n "$venv" ] && line+=" ${flag}py:${venv//[\\\`\$]/}"

  local REPLY secs
  if [ -n "$__prompt_t0" ]; then
    secs=$((SECONDS - __prompt_t0))
    unset __prompt_t0
    if [ "$secs" -ge 5 ]; then
      __prompt_elapsed "$secs"
      line+=" $dim$REPLY"
    fi
  fi

  # jobs is a builtin, but reading its output back costs the one subshell.
  local jp nl
  jp=$(jobs -p)
  nl=${jp//[!$'\n']/}
  [ -n "$jp" ] && line+=" $dim&$(( ${#nl} + 1 ))"

  # The exit code and the prompt character carry the same signal. Two places
  # because the eye finds the second one without looking.
  local mark=$off
  if [ "$status" != 0 ]; then
    line+=" ${bad}!$status"
    mark=$bad
  fi

  PS1="$line$off\\n$mark$__prompt_char $off"
  __prompt_armed=1
}

PROMPT_COMMAND='__prompt $?'

# ZVM
export ZVM_INSTALL="$HOME/.zvm/self"
if [ -d "$ZVM_INSTALL" ]; then
  export PATH="$PATH:$HOME/.zvm/bin"
  export PATH="$PATH:$ZVM_INSTALL"
fi
