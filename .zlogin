# Aliases for OSX
alias ls='ls -CFG'

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

# Add RVM to PATH for scripting
export PATH="$PATH:$HOME/.rvm/bin" 

# Load RVM into a shell session *as a function*
[[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm" 
