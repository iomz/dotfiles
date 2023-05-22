#!/usr/bin/env zsh
#
# Environmental values not in .zshenv
#
# no-ops
#

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

# zeno.zsh {{{
# if defined load the configuration file from there
export ZENO_HOME=${XDG_CONFIG_HOME}/zeno

# if disable zeno cache command when plugin loaded
export ZENO_DISABLE_EXECUTE_CACHE_COMMAND=1

# if enable fzf-tmux
export ZENO_ENABLE_FZF_TMUX=1

# if setting fzf-tmux options
export ZENO_FZF_TMUX_OPTIONS="-p"

# Experimental: Use UNIX Domain Socket
#export ZENO_ENABLE_SOCK=1

# if disable builtin completion
#export ZENO_DISABLE_BUILTIN_COMPLETION=1

# default
#export ZENO_GIT_CAT="cat"
# git file preview with color
export ZENO_GIT_CAT="bat --color=always"

# default
#export ZENO_GIT_TREE="tree"
# git folder preview with color
export ZENO_GIT_TREE="exa --tree"
# }}}
