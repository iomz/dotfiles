# Brew
if (( ! $+commands[brew] )); then
    if [[ -x /opt/homebrew/bin/brew ]]; then
        BREW_LOCATION="/opt/homebrew/bin/brew"
    elif [[ -x /usr/local/bin/brew ]]; then
        BREW_LOCATION="/usr/local/bin/brew"
    elif [[ -x /home/linuxbrew/.linuxbrew/bin/brew ]]; then
        BREW_LOCATION="/home/linuxbrew/.linuxbrew/bin/brew"
    elif [[ -x "$HOME/.linuxbrew/bin/brew" ]]; then
        BREW_LOCATION="$HOME/.linuxbrew/bin/brew"
    else
        return
    fi
    eval "$("$BREW_LOCATION" shellenv)"
    unset BREW_LOCATION
    path=( ${HOMEBREW_PREFIX}/(s|)bin $path )
    fpath=( $HOMEBREW_PREFIX/share/zsh/site-functions(/N) $fpath )
    # brew curl
    if [[ -x /opt/homebrew/opt/curl/bin/curl ]]; then
        path=( /opt/homebrew/opt/curl/bin $path )
    fi
fi

# Deno
path=(~/.deno/bin(N-/) $path)

# Go
path=(/usr/local/go/bin(N-/) $path)
if whence go > /dev/null; then
    export GOPATH=$HOME/go
    path=(
        $GOPATH/bin(N-/)
        $HOME/.ghg/bin(N-/) # https://github.com/Songmu/ghg
        /usr/local/go/bin(N-/)
        $path
    )
fi

# Java
export JAVA_HOME=$(/usr/libexec/java_home -v "14")

# LLVM
path=(/usr/local/opt/llvm/bin(N-/) $path)

# Node Version Manager: node, npm, and yarn
# nvm init option 0: -------------------------
export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # This loads nvm
# nvm init option 1: -------------------------
#export NVM_DIR=$HOME/.config/nvm
#[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
#[ -s "$NVM_DIR/bash_completion" ] && . "$NVM_DIR/bash_completion"
# nvm init option 2: -------------------------
#if [ -s "$HOME/.config/nvm/nvm.sh" ]; then
#    export NVM_DIR="$HOME/.config/nvm"
#    nvm_cmds=(nvm node npm yarn)
#    for cmd in $nvm_cmds ; do
#        alias $cmd="unalias $nvm_cmds && unset nvm_cmds && . $NVM_DIR/nvm.sh && $cmd"
#    done
#    [ -s "$NVM_DIR/bash_completion" ] && . "$NVM_DIR/bash_completion"
#fi
# nvm init option 3: -------------------------
#declare -a __node_commands=('nvm' 'node' 'npm' 'yarn' 'gulp' 'grunt' 'webpack')
#function __init_nvm() {
#  for i in "${__node_commands[@]}"; do unalias $i; done
#  . "$NVM_DIR"/nvm.sh
#  unset __node_commands
#  unset -f __init_nvm
#}
#for i in "${__node_commands[@]}"; do alias $i='__init_nvm && '$i; done
# nvm init option 4: -------------------------
#export NVM_DIR=$HOME/.config/nvm
#NODEPATH="$(find $NVM_DIR/ -type d -regex ".*/v[0-9.]*/bin")"
#export PATH=$NODEPATH:$PATH
# --------------------------------------------

# Python
if command -v ~/.pyenv/bin/pyenv 1> /dev/null 2>&1; then
    export PYENV_ROOT="$HOME/.pyenv"
    path=($PYENV_ROOT/bin(N-/) $path)
    source $PYENV_ROOT/completions/pyenv.zsh
    # cf. https://github.com/pyenv/pyenv-virtualenv/issues/387
    eval "$(pyenv init --path)"
    eval "$(pyenv init -)"
    eval "$(pyenv virtualenv-init -)"
fi

# Rust
if command -v ~/.cargo/bin/cargo 1> /dev/null 2>&1; then
    path=($HOME/.cargo/bin(N-/) $path)
    source $HOME/.cargo/env
fi

# Ruby
if whence rbenv > /dev/null; then
    eval "$(rbenv init - zsh)"
fi

# $HOME/bin
path=($HOME/bin(N-/) $path)
