#!/usr/bin/env bash
#
# Bash configuration, laid out after Dave Eddy's bashrc in bahamas10/dotfiles.
#
# One file, split into "# -- Section" blocks. PATH, environment, and the Emacs
# helpers come before the interactive guard so non-interactive shells such as
# ssh commands and editor subshells still get them. Everything after the guard
# is for a terminal. The prompt is built once by prompt-init and shows the last
# exit code and git branch inline. Machine-specific settings go in
# ~/.bashrc.local, which loads last so it can override anything here.

# -- PATH

_path_prepend() {
	local dir=$1

	[[ -d $dir && :$PATH: != *":$dir:"* ]] && PATH=$dir:$PATH
}

if [[ -d /opt/homebrew ]]; then
	_dotfiles_homebrew_prefix=/opt/homebrew
elif [[ -d /usr/local/Homebrew ]]; then
	_dotfiles_homebrew_prefix=/usr/local
fi
if [[ -n ${_dotfiles_homebrew_prefix:-} ]]; then
	_path_prepend "$_dotfiles_homebrew_prefix/sbin"
	_path_prepend "$_dotfiles_homebrew_prefix/bin"
	_path_prepend "$_dotfiles_homebrew_prefix/opt/universal-ctags/bin"
fi

_path_prepend "$HOME/go/bin"
_path_prepend "$HOME/.cargo/bin"
_path_prepend "$HOME/.config/emacs/bin"
_path_prepend "$HOME/.local/bin"
_path_prepend "/Applications/Emacs.app/Contents/MacOS/bin"

if [[ -x /usr/libexec/java_home ]]; then
	_dotfiles_java_home=$(/usr/libexec/java_home 2>/dev/null) \
		|| _dotfiles_java_home=
	if [[ -n $_dotfiles_java_home ]]; then
		export JAVA_HOME=$_dotfiles_java_home
		_path_prepend "$JAVA_HOME/bin"
	fi
fi

if [[ -d $HOME/.bun/bin ]]; then
	export BUN_INSTALL=$HOME/.bun
	_path_prepend "$BUN_INSTALL/bin"
fi

if [[ -d $HOME/.zvm ]]; then
	export ZVM_INSTALL=$HOME/.zvm/self
	_path_prepend "$ZVM_INSTALL"
	_path_prepend "$HOME/.zvm/bin"
fi
unset _dotfiles_homebrew_prefix _dotfiles_java_home
unset -f _path_prepend
export PATH

# -- Environment

if command -v nvim &>/dev/null; then
	export EDITOR=nvim
else
	export EDITOR=${EDITOR:-vi}
fi
export VISUAL=$EDITOR
export PAGER=less
export MANPAGER=less

export CLICOLOR=1
export LSCOLORS=GxFxBxdxCxDxdxabagacad

# Colorized man pages. GROFF_NO_SGR makes groff emit the codes less recolors.
export GROFF_NO_SGR=1
export LESS_TERMCAP_mb=$'\e[1;31m'
export LESS_TERMCAP_md=$'\e[1;31m'
export LESS_TERMCAP_me=$'\e[0m'
export LESS_TERMCAP_se=$'\e[0m'
export LESS_TERMCAP_so=$'\e[1;33;44m'
export LESS_TERMCAP_ue=$'\e[0m'
export LESS_TERMCAP_us=$'\e[4;1;32m'

# -- Emacs

if command -v emacsclient &>/dev/null; then
	alias emacs='emacsclient -c -n'
	alias e='emacsclient -n'
	alias et='emacsclient -t'
fi

_emacsctl_wait_ready() {
	local attempt
	for attempt in {1..20}; do
		command emacsclient -e '(emacs-version)' >/dev/null 2>&1 && return
		sleep 0.5
	done
	printf 'Emacs daemon failed to become ready\n' >&2
	return 1
}

emacsctl() {
	local label=dev.nathantebbs.emacs
	local target="gui/$(id -u)/$label"

	case ${1:-} in
		start)
			if ! launchctl bootstrap "gui/$(id -u)" \
				"$HOME/Library/LaunchAgents/$label.plist" 2>/dev/null; then
				launchctl kickstart "$target"
			fi
			_emacsctl_wait_ready
			;;
		stop)
			launchctl bootout "$target"
			;;
		restart)
			launchctl print "$target" >/dev/null 2>&1 \
				&& launchctl bootout "$target"
			sleep 1
			launchctl bootstrap "gui/$(id -u)" \
				"$HOME/Library/LaunchAgents/$label.plist"
			_emacsctl_wait_ready
			;;
		status)
			if command emacsclient -e '(emacs-version)' >/dev/null 2>&1; then
				printf 'Emacs daemon: running\n'
			else
				printf 'Emacs daemon: stopped\n'
			fi
			;;
		logs)
			log show --last 1h --style compact \
				--predicate 'process == "Emacs"'
			;;
		*)
			printf 'Usage: emacsctl {start|stop|restart|status|logs}\n'
			return 1
			;;
	esac
}

# If not running interactively, don't do anything else.
[[ $- == *i* ]] || return 0

# -- Shell options

# History is shared between open shells by prompt-update.
HISTCONTROL=ignoreboth
HISTSIZE=10000
HISTFILESIZE=20000

shopt -s autocd
shopt -s cdspell
shopt -s checkwinsize
shopt -s dirspell
shopt -s extglob
shopt -s histappend

bind '"\e[A": history-search-backward'
bind '"\e[B": history-search-forward'

# -- Aliases

alias l='ls -lah'
alias csv="column -t -s ',' | less -S"
alias hl='rg --passthru'
alias nv='nvim'

# Aliases (if applicable)
grep --color=auto < /dev/null &>/dev/null &&
	alias grep='grep --color=auto'
command -v xdg-open &>/dev/null &&
	alias open='xdg-open'

if ls --color=auto /dev/null &>/dev/null; then
	alias ls='ls --color=auto'
elif ls -G /dev/null &>/dev/null; then
	alias ls='ls -G'
fi

# -- Git

alias g='git'
alias gd='git diff'
alias gl='git log --oneline --decorate --graph'
alias gr='git rev-parse --show-toplevel' # git root
alias gs='git status --short --branch'

# The main branch may be master, main, or something else, so ask the remote.
gmb() { # git main branch
	local main
	main=$(git symbolic-ref --short refs/remotes/origin/HEAD) || return 1
	echo "${main#origin/}"
}

gbd() { # git branch diff against the main branch
	local mb
	mb=$(gmb) || return 1
	git diff "$mb..HEAD"
}

gcm() { # git checkout main and update it
	local mb
	mb=$(gmb) || return 1
	git checkout "$mb" && git pull
}

gmm() { # git merge main into this branch
	local mb
	mb=$(gmb) || return 1
	git merge "$mb"
}

# -- Prompt

prompt-init() {
	local red=$'\e[31m'
	local green=$'\e[32m'
	local yellow=$'\e[33m'
	local blue=$'\e[34m'
	local magenta=$'\e[35m'
	local bold=$'\e[1m'
	local reset=$'\e[0m'

	# [(exit code)] <user>@<host> <cwd> [(git:branch)] <$|#>
	# ANSI colors only, so the terminal theme decides the actual shades.

	PS1='$(c=$?;((c))&&echo "\['"$red"'\]($c) \['"$reset"'\]")'

	# username (red for root)
	PS1+='\['"$bold$yellow"'\]$(((UID==0))&&echo "\['"$red"'\]")\u'
	PS1+='\['"$reset"'\]@'

	PS1+='\['"$green"'\]\h '
	PS1+='\['"$blue"'\]\w '

	# Kept on one line because every subshell here runs on each prompt.
	PS1+='$(b=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)&&echo "\['"$magenta"'\](git:$b) ")'

	PS1+='\['"$reset"'\]\$ '
}

prompt-update() {
	history -a
	history -n

	# \w expanded through @P escapes control characters in the path.
	local s='\w'
	local ssh=
	[[ -n $SSH_CLIENT ]] && ssh='[ssh] '
	printf '\e]0;%s%s@%s:%s\a' "$ssh" "$USER" "${HOSTNAME%%.*}" "${s@P}"
}

PROMPT_COMMAND=prompt-update
PROMPT_DIRTRIM=6

prompt-init

# -- Useful functions

# Print all 256 colors
colors() {
	local i
	for i in {0..255}; do
		printf '\e[38;5;%dmcolor %d\n' "$i" "$i"
	done
	printf '\e[0m'
}

# Copy stdin to the clipboard
copy() {
	pbcopy 2>/dev/null ||
		wl-copy 2>/dev/null ||
		xsel -b 2>/dev/null
}

# Convert epoch to human readable (print current date if no args)
epoch() {
	local num=${1:--1}
	printf '%(%B %d, %Y %-I:%M:%S %p %Z)T\n' "$num"
}

# Open the current path or file in GitHub
gho() {
	local file=$1
	local remote=${2:-origin}

	local gr branch url
	gr=$(git rev-parse --show-toplevel) || return 1
	branch=$(git rev-parse --abbrev-ref HEAD) || return 1
	url=$(git config --get "remote.$remote.url") || return 1

	local path=${PWD/#$gr/}
	[[ -n $file ]] && path+=/$file

	# Handles both git@github.com:user/repo.git and https URLs.
	local a
	IFS=:/ read -r -a a <<< "$url"
	local len=${#a[@]}
	local user=${a[len-2]}
	local repo=${a[len-1]%.git}

	url="https://github.com/$user/$repo/tree/$branch$path"
	echo "$url"
	open "$url"
}

# Print lines over X columns (defaults to 80)
over() {
	local c=${1:-80}
	expand | awk -v "c=$c" 'length($0) > c {
		printf("%4d %s\n", NR, $0);
	}'
}

# Follow redirects to untiny a tiny url
untiny() {
	local url=$1

	while [[ -n $url ]]; do
		echo "-> $url"
		url=$(curl -sSI -o /dev/null -w '%header{location}' "$url") \
			|| return 1
	done
}

# -- Local overrides and completion

[[ -r ~/.bashrc.local ]] && . ~/.bashrc.local
[[ -r ~/.bash_completion ]] && . ~/.bash_completion

# Return success no matter what.
true
