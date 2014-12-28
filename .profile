# alias
alias ls='ls -CFG'
alias ll='ls -ahlFG'
alias la='ls -AG'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'

# It is the default value on OSX, so this line can be omitted
#export LSCOLORS=exfxcxdxbxegedabagacad
export LSCOLORS=cxGxbxexFxdhdhbxbxcxcx

# Locale setting
export LC_ALL=en_US.UTF-8

# Python environment 
export HOMEBREW_PREFIX=/usr/local/Cellar

# UpTeX bin PATH
#export PATH=/Applications/UpTeX.app/teTeX/bin:$PATH

# usr sbin
export PATH="/usr/local/sbin:$PATH"

# user bin
export PATH="/usr/local/bin:$PATH"

# golang enviromental set up
export GOPATH=$HOME/go
export GOROOT=/usr/local/go
export PATH=$PATH:$GOROOT/bin

# Android Studio
#export STUDIO_JDK=/Library/Java/JavaVirtualMachines/jdk1.8.0_25.jdk
