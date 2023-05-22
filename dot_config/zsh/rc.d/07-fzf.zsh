#!/usr/bin/env zsh
#
# FZF-specific configuration
#

# default command
if whence rg > /dev/null; then
    export FZF_DEFAULT_COMMAND="rg --files --hidden --follow --glob '!.git'"
else
    export FZF_DEFAULT_COMMAND="find -not -path '*/\.git/*'"
fi

# default options
export FZF_DEFAULT_OPTS="--info inline --layout reverse"
#\export FZF_DEFAULT_OPTS='--reverse --color=hl:#81A1C1,hl+:#81A1C1,info:#EACB8A,prompt:#81A1C1,pointer:#B48DAC,marker:#A3BE8B,spinner:#B48DAC,header:#A3BE8B'

# completion trigger
export FZF_COMPLETION_TRIGGER=';'
