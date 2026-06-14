#!/usr/bin/env zsh
#
# Environmental values not in .zshenv
#

# $PATH and $path (and also $FPATH and $fpath, etc.) are "tied" to each other.
# Modifying one will also modify the other.
# Note that each value in an array is expanded separately. Thus, we can use ~
# for $HOME in each $path entry.
typeset -gU FPATH PATH fpath path
fpath=( $HOME/.config/zsh/(func|comple)tions(N) $fpath )
autoload -Uz ~/.config/zsh/functions/**/*

path=(
    /usr/local/bin(N-/)
    /usr/bin(N-/)
    /bin(N-/)
    /usr/local/sbin(N-/)
    /usr/sbin(N-/)
    /sbin(N-/)
    /usr/X11/bin(N-/)
)
fpath=(
    ~/.zsh/completions(N-/)
    $fpath
)

# Brew
if [[ -z "${TINY_CHEZMOI}" ]]; then # not TINY_CHEZMOI
    if [[ -x /opt/homebrew/bin/brew ]]; then
        BREW_LOCATION="/opt/homebrew/bin/brew"
    elif [[ -x /usr/local/bin/brew ]]; then
        BREW_LOCATION="/usr/local/bin/brew"
    elif [[ -x /home/linuxbrew/.linuxbrew/bin/brew ]]; then
        BREW_LOCATION="/home/linuxbrew/.linuxbrew/bin/brew"
    elif [[ -x "$HOME/.linuxbrew/bin/brew" ]]; then
        BREW_LOCATION="$HOME/.linuxbrew/bin/brew"
    fi
    if [[ -n "${BREW_LOCATION}" ]]; then
        eval "$("$BREW_LOCATION" shellenv)"
        unset BREW_LOCATION
        path=( ${HOMEBREW_PREFIX}/(s|)bin $path )
        fpath=( $HOMEBREW_PREFIX/share/zsh/site-functions(/N) $fpath )
        # brew curl
        if [[ -x /opt/homebrew/opt/curl/bin/curl ]]; then
            path=( /opt/homebrew/opt/curl/bin $path )
        fi
        # brew gnu awk
        if [[ -x /opt/homebrew/opt/gawk/libexec/gnubin/awk ]]; then
            path=( /opt/homebrew/opt/gawk/libexec/gnubin $path )
        fi
    fi
fi

# Go
export GOPATH=$HOME/go
path=( $GOPATH/bin(N-/) $HOME/.ghg/bin(N-/) $path )

# LLVM
path=(/usr/local/opt/llvm/bin(N-/) $path)

# Rust - cargo, rustup and rustc
if [[ -z "${TINY_CHEZMOI}" ]] && [[ -x $HOME/.cargo/bin/cargo ]]; then
    path=($HOME/.cargo/bin(N-/) $path)
    source $HOME/.cargo/env
fi

# Deno global scripts installed by `deno install --global`
# The Deno runtime itself is managed by mise.
export DENO_INSTALL="${DENO_INSTALL:-$HOME/.deno}"
path=("${DENO_INSTALL}/bin"(N-/) $path)

# pnpm global binaries
# The pnpm runtime itself is managed by mise.
export PNPM_HOME="${PNPM_HOME:-$HOME/.local/share/pnpm}"
path=("${PNPM_HOME}"(N-/) $path)

# Snap
if [[ -d /snap/bin ]]; then
    path=(/snap/bin(N-/) $path)
fi

# $HOME/.local/bin and $HOME/bin
path=($HOME/.local/bin(N-/) $HOME/bin(N-/) $path)

# fzf {{{
# default command
if whence rg > /dev/null; then
    export FZF_DEFAULT_COMMAND="rg --files --hidden --follow -g '!.git' -g '!Library' -g '!.cache' -g '!.Trash'"
else
    export FZF_DEFAULT_COMMAND="find -path '*.git/*' -prune -o -path '*Library/*' -prune -o -print"
fi

# default options
export FZF_DEFAULT_OPTS="--info inline --layout reverse"
#\export FZF_DEFAULT_OPTS='--reverse --color=hl:#81A1C1,hl+:#81A1C1,info:#EACB8A,prompt:#81A1C1,pointer:#B48DAC,marker:#A3BE8B,spinner:#B48DAC,header:#A3BE8B'

# completion trigger
export FZF_COMPLETION_TRIGGER=';'
# }}}

# zsh-autosuggestions {{{
export ZSH_AUTOSUGGEST_USE_ASYNC=1
export ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=8'
ZSH_AUTOSUGGEST_CLEAR_WIDGETS+=(
    accept-line
    backward-delete-char
    backward-kill-word
    kill-line
    kill-word
    unix-word-rubout
    zeno-auto-snippet-and-accept-line
)
# }}}
