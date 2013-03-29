# It is the default value on OSX, so this line can be omitted
#export LSCOLORS=exfxcxdxbxegedabagacad
export LSCOLORS=cxGxbxexFxdhdhbxbxcxcx

# alias
alias ls='ls -CFG'
alias ll='ls -ahlFG'
alias la='ls -AG'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'

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

# Add RVM to PATH for scripting
PATH=$PATH:$HOME/.rvm/bin 
