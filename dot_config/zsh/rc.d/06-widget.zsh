#!/usr/bin/env zsh
#
# Widget
#

# url quote magic
autoload -Uz url-quote-magic
zle -N self-insert url-quote-magic

zmodload -i zsh/parameter
autoload -Uz zkbd

function _accept-line-with-url {
    if [[ $BUFFER =~ ^https.*git ]]; then
        echo $BUFFER >> $HISTFILE
        fc -R
        BUFFERz="git clone $BUFFER && cd $(basename $BUFFER .git)"
        zle .kill-whole-line
        BUFFER=$BUFFERz
        zle .accept-line
    elif [[ $BUFFER =~ ^[[:space:]]?\$[[:space:]] ]]; then
        echo $BUFFER >> $HISTFILE
        fc -R
        BUFFERz="$(echo ${BUFFER/\$/} | xargs)"
        BUFFER=$BUFFERz
        zle .accept-line
    else
        zle .accept-line
    fi
}
zle -N accept-line _accept-line-with-url

# Bind <alt>+s to `git status`
function _git-status {
    zle .kill-whole-line
    BUFFER="git status"
    zle .accept-line
}
zle -N _git-status && bindkey '\es' _git-status

insert-last-command-output() {
    LBUFFER+="$(eval $history[$((HISTCMD-1))])"
}
zle -N insert-last-command-output && bindkey -M vicmd '\ew' insert-last-command-output

function prepend-sudo {
    if [[ $BUFFER != "sudo "* ]]; then
        BUFFER="sudo $BUFFER"; CURSOR+=5
    fi
}
zle -N prepend-sudo && bindkey -M vicmd s prepend-sudo

function reset_broken_terminal() {
    printf '%b' '\e[0m\e(B\e)0\017\e[?5l\e7\e[0;0r\e8'
}
autoload -Uz add-zsh-hook
add-zsh-hook -Uz precmd reset_broken_terminal

# python venv {{{
python_venv() {
    MYVENV=./venv
    # when you cd into a folder that contains $MYVENV
    [[ -d $MYVENV ]] && source $MYVENV/bin/activate > /dev/null 2>&1
    # when you cd into a folder that doesn't
    [[ ! -d $MYVENV ]] && deactivate > /dev/null 2>&1
}
autoload -U add-zsh-hook
add-zsh-hook chpwd python_venv

python_venv
#}}}
