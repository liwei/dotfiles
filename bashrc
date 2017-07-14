# .bashrc

# Source global definitions
if [ -f /etc/bashrc ]; then
	. /etc/bashrc
fi

# User specific aliases and functions
# alias
alias ls="ls --color"
alias la="ls -a"
alias ll="ls -l"
alias vi="vim"
alias xclip='xclip -selection clipboard'

# exports
export EDITOR=vim

# highlight prompt when error occurred
PS1='`[ $? -ne 0 ] && echo -ne "\[\033[01;32;41m\]"`\[\033[01;32m\]\u@\h \W \$\[\033[1;0m\] '
