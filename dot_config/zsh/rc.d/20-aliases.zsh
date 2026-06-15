#!/usr/bin/env zsh
#
# Aliases
#

# +────────+
# │ CONFIG │
# +────────+
alias cdot='cd "${XDG_DATA_HOME:-$HOME/.local/share}/chezmoi"'
alias cdv='cd "${XDG_CONFIG_HOME:-$HOME/.config}/nvim"'

# +───────────────────+
# │ COMMAND SHORTCUTS │
# +───────────────────+
alias auld='builtin autoload'
alias me='builtin print -P "%F{blue}$(whoami)%f @ %F{cyan}$(uname -a)%f"'
alias mk='make'
alias zc='zinit compile'
alias zht='hyperfine --warmup 100 --runs 10000 "/bin/ls"'
alias zmld="builtin zmodload"

# +───────+
# │ MISC. │
# +───────+
#alias -- +x='chmod +x'
#alias -- \?='which'
alias gen-pwd='openssl rand -base64 24'
alias show-env='print -lio $(env)'
alias show-path='print -l ${(@s[:])PATH}'
alias show-sys='echo OSTYPE=${OSTYPE} MACHTYPE=${MACHTYPE} CPUTYPE=${CPUTYPE} hardware=$(uname -m) processor=$(uname -p)'
alias tmp='$EDITOR $(mktemp -t scratch.XXX.md)'

# +──────────────+
# │ NETWORK INFO │
# +──────────────+
alias show-open-tcp-ports='sudo lsof -i -n -P | grep TCP'
#alias ping='ping -c 10'

# +─────────+
# │ DEFAULT │
# +─────────+
if whence bat > /dev/null; then
    alias bat="bat --color=always"
fi

# exa
if whence exa > /dev/null; then
    alias l='exa -blF'
    alias la='exa -abghilmu'
    #alias la="exa -alh --git --time-style long-iso"
    alias ll="exa -lh  --git --time-style long-iso"
    #alias ll='exa -al'
    alias ls='exa --git --group-directories-first'
    #alias ls="exa"
    alias tree='exa --tree'
elif whence gls > /dev/null; then
    alias ls='gls --color=auto'
    alias ll='ls -lh'
    alias la='ls -alh'
else
    alias ll='ls -lh'
    alias la='ls -alh'
fi

# nvim
if whence nvim > /dev/null; then
    for i (v vi vim); do
        alias $i="nvim"
    done
    alias vimdiff='nvim -d'
fi

# sed
if whence gsed > /dev/null; then
    alias sed='gsed'
fi

# zellij
if whence zellij > /dev/null; then
    alias zj='zellij attach --create main'
    alias za='zellij attach alter -c'
    alias zb='zellij attach brain -c'
    alias zd='zellij attach dotfiles -c'
    alias zs='zellij attach scratch -c'
fi

# tail
alias lt='tail -n 160'
alias lr='less -R'
