# Load tmux on login
# if [ "$TMUX" = "" ]; then tmux attach; fi

bindkey -e

autoload -U compinit
compinit

setopt list_packed
setopt list_types
setopt auto_cd
setopt auto_pushd
setopt correct
setopt noautoremoveslash
setopt print_eight_bit

zstyle ':completion:*' list-colors 'di=36' 'ln=35'
zstyle ':completion:*:default' menu select=1

#autoload predict-on
#predict-on

autoload -U colors && colors

# Setting the style and the color of prompt
#PROMPT=$'%{\e[0;31m%}%* %n$ '
PROMPT="%{$fg[cyan]%}%n%{$reset_color%}@%{$fg[green]%}%m %{$fg[red]%}%1~ %{$reset_color%}%#"
#RPROMPT=$'%{\e[0;33m%}%/%{\e[m%}'
RPROMPT="%{$fg[yellow]%}%/%{$reset_color%}%"

HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt hist_ignore_dups
setopt share_history
setopt append_history
setopt inc_append_history
setopt hist_no_store
setopt hist_reduce_blanks

# It is the default value on OSX, so this line can be omitted
##export LSCOLORS=gxfxxxxxcxxxxxxxxxxxxx
export LSCOLORS=exfxcxdxbxegedabagacad

# Locale setting
export LC_ALL=en_US.UTF-8
# export LANG="en_US.UTF-8"
# export LANG="ja_JP.UTF-8"
# export LANGUAGE="en_US.UTF-8"

# alias
alias ls='ls -CFG'
alias ll='ls -ahlFG'
alias la='ls -AG'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'

# Display process taken longer than 3 seconds
REPORTTIME=3

# Python environment 
PYTHON_VER=2.7.3
export HOMEBREW_PREFIX=/usr/local/Cellar
# export VIRTUALENV_BIN=$MACPORTS_PREFIX/Library/Frameworks/Python.framework/Versions/$PYTHON_VER/bin
# export PYTHONPATH=$HOMEBREW_PREFIX/python/$PYTHON_VER/bin
export PYTHONPATH=/usr/local/share/python:$HOMEBREW_PREFIX/python/$PYTHON_VER/bin
export PATH=$PYTHONPATH:$PATH
export WORKON_HOME=$HOME/.virtualenvs
. /usr/local/share/python/virtualenvwrapper.sh

mkvenv () {
    base_python=`which python$1` 
    mkvirtualenv --distribute --python=$base_python $2
}

# UpTeX bin PATH
export PATH=/Applications/UpTeX.app/teTeX/bin:$PATH

# RVM loader
if [[ -s /Users/iomz/.rvm/scripts/rvm ]] ; then source /Users/iomz/.rvm/scripts/rvm ; fi

# NPM module search path
# export NODE_PATH=/usr/local/lib/node_modules

# OMNeT++ bin/ directory
# export PATH=$PATH:$HOME/omnetpp-4.1/bin

# OSX Lion update
# export PATH=$PATH:/Developer/usr/bin

# Load RVM
# [[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm"

# Script to linux env ???
# test -r /sw/bin/init.sh && . /sw/bin/init.sh

# MacPorts Modifier
# export PATH=/opt/local/bin:/opt/local/sbin:/usr/local/bin:$PATH
# export MANPATH=/opt/local/share/man:/opt/local/lib/node_modules/npm/man/:$MANPATH

# User bin PATH
export PATH=$HOME/bin:$PATH


PATH=$PATH:$HOME/.rvm/bin # Add RVM to PATH for scripting
