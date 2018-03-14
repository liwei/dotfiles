# .bashrc

# Source global definitions
if [ -f /etc/bashrc ]; then
	. /etc/bashrc
fi

# User specific aliases and functions
# alias
alias ls="ls --color=auto"
alias la="ls -a"
alias ll="ls -l"
alias vi="vim"
alias xclip='xclip -selection clipboard'

# exports
export EDITOR=vim
export GOPATH=$HOME/go
export PATH=~/.local/bin:$PATH:$GOPATH/bin

# highlight prompt when error occurred
PS1='`[ $? -ne 0 ] && echo -ne "\[\033[01;32;41m\]"`\[\033[01;32m\]\u@\h \W \$\[\033[1;0m\] '

# colorized manpages
man() {
    env \
    LESS_TERMCAP_mb="$(printf "\e[1;31m")" \
    LESS_TERMCAP_md="$(printf "\e[1;31m")" \
    LESS_TERMCAP_me="$(printf "\e[0m")" \
    LESS_TERMCAP_se="$(printf "\e[0m")" \
    LESS_TERMCAP_so="$(printf "\e[1;44;33m")" \
    LESS_TERMCAP_ue="$(printf "\e[0m")" \
    LESS_TERMCAP_us="$(printf "\e[1;32m")" \
    man "${@}"
}
