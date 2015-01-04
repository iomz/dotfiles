# alias
alias ls='ls -CFG'
alias ll='ls -ahlFG'
alias la='ls -AG'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'

# It is the default value on OSX, so this line can be omitted
#export LSCOLORS=exfxcxdxbxegedabagacad
export LSCOLORS=""
# directory
export LSCOLORS=$LSCOLORS"gx"
# symboic link
export LSCOLORS=$LSCOLORS"fx"
# socket
export LSCOLORS=$LSCOLORS"cx"
# pipe
export LSCOLORS=$LSCOLORS"Fx"
# executable
export LSCOLORS=$LSCOLORS"ex"
# block special
export LSCOLORS=$LSCOLORS"ah"
# character special
export LSCOLORS=$LSCOLORS"bh"
# executable with setuid bit set
export LSCOLORS=$LSCOLORS"bx"
# executable with setgid bit set
export LSCOLORS=$LSCOLORS"bx"
# directory writable to others, with sticky bit
export LSCOLORS=$LSCOLORS"cx"
# directory writable to others, without sitcky bit
export LSCOLORS=$LSCOLORS"cx"

# Locale setting
export LC_ALL=en_US.UTF-8

# UpTeX bin PATH
#export PATH="/Applications/UpTeX.app/teTeX/bin:$PATH"

# Add /usr/local/bin to PATH
export HOMEBREW_PREFIX="/usr/local/Cellar"
export PATH="/usr/local/bin:$PATH"

# golang enviromental set up
export GOPATH="$HOME/go"
export GOROOT="/usr/local/opt/go/libexec"
export PATH="$GOROOT/bin:$PATH"

# Android Studio
export STUDIO_JDK="/Library/Java/JavaVirtualMachines/jdk1.8.0_25.jdk"

export PATH="$PATH:$HOME/.rvm/bin" # Add RVM to PATH for scripting

[[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm" # Load RVM into a shell session *as a function*
