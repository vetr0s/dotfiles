# User-installed tools, when present.
_path_prepend() {
	local dir=$1

	[[ -d $dir && :$PATH: != *":$dir:"* ]] && PATH=$dir:$PATH
}

_path_prepend "$HOME/go/bin"
_path_prepend "$HOME/.cargo/bin"
_path_prepend "$HOME/.config/emacs/bin"
_path_prepend "$HOME/.local/bin"

if [[ -d $HOME/.bun/bin ]]; then
	export BUN_INSTALL=$HOME/.bun
	_path_prepend "$BUN_INSTALL/bin"
fi

if [[ -d $HOME/.zvm ]]; then
	export ZVM_INSTALL=$HOME/.zvm/self
	_path_prepend "$ZVM_INSTALL"
	_path_prepend "$HOME/.zvm/bin"
fi
unset -f _path_prepend
export PATH

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
