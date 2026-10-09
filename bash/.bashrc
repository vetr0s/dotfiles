# User-installed tools, when present.
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

export CLICOLOR=1
export LSCOLORS=GxFxBxdxCxDxdxabagacad

if command -v emacsclient &>/dev/null; then
	export EDITOR='emacsclient -a vi'
	export VISUAL=$EDITOR
	alias emacs='emacsclient -c -n'
	alias e='emacsclient -n'
	alias et='emacsclient -t'
else
	export EDITOR=${EDITOR:-vi}
	export VISUAL=${VISUAL:-$EDITOR}
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

[[ $- == *i* ]] || return

# History shared between open shells.
HISTCONTROL=ignoreboth
HISTSIZE=10000
HISTFILESIZE=20000
shopt -s checkwinsize histappend

bind '"\e[A": history-search-backward'
bind '"\e[B": history-search-forward'

_prompt() {
	local status=$?

	history -a
	history -n

	PS1='\[\e[36m\]\u@\h\[\e[0m\]:\[\e[34m\]\w\[\e[0m\]'
	((status)) && PS1+=" \[\e[31m\][$status]\[\e[0m\]"
	PS1+=' \$ '
}
PROMPT_COMMAND=_prompt
PROMPT_DIRTRIM=4

alias l='ls -lah'
alias g='git'
alias gs='git status --short --branch'
alias gd='git diff'
alias gl='git log --oneline --decorate --graph'
alias csv="column -t -s ',' | less -S"

if ls --color=auto /dev/null &>/dev/null; then
	alias ls='ls --color=auto'
elif ls -G /dev/null &>/dev/null; then
	alias ls='ls -G'
fi

if command -v less &>/dev/null; then
	# Colorized man pages, adapted from Dave Eddy's termcap.bash.
	export GROFF_NO_SGR=1
	export MANPAGER=less
	export LESS_TERMCAP_mb=$'\e[1;31m'
	export LESS_TERMCAP_md=$'\e[1;31m'
	export LESS_TERMCAP_me=$'\e[0m'
	export LESS_TERMCAP_se=$'\e[0m'
	export LESS_TERMCAP_so=$'\e[1;33;44m'
	export LESS_TERMCAP_ue=$'\e[0m'
	export LESS_TERMCAP_us=$'\e[4;1;32m'
fi
