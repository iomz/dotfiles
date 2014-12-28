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
export HOMEBREW_PREFIX=/usr/local/Cellar

# UpTeX bin PATH
export PATH=/Applications/UpTeX.app/teTeX/bin:$PATH

# User bin PATH
export PATH=$HOME/bin:$HOME/repos/binfiles:$PATH

# usr sbin
export PATH="/usr/local/sbin:$PATH"

# user bin
export PATH="/usr/local/bin:$PATH"

# depot_tool
export PATH=/opt/depot_tools:$PATH

##
# Your previous /Users/iomz/.profile file was backed up as /Users/iomz/.profile.macports-saved_2013-12-18_at_16:36:24
##

# MacPorts Installer addition on 2013-12-18_at_16:36:24: adding an appropriate PATH variable for use with MacPorts.
export PATH=/opt/local/bin:/opt/local/sbin:$PATH
# Finished adapting your PATH environment variable for use with MacPorts.

# golang enviromental set up
export GOROOT=/usr/local/go
export GOPATH=$HOME/go
export PATH=$PATH:$GOPATH/bin
