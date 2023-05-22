#!/usr/bin/env zsh
#
# zeno.zsh specific configurations
#

# if defined load the configuration file from there
export ZENO_HOME=${XDG_CONFIG_HOME}/zeno

# if disable zeno cache command when plugin loaded
# export ZENO_DISABLE_EXECUTE_CACHE_COMMAND=1

# if enable fzf-tmux
export ZENO_ENABLE_FZF_TMUX=1

# if setting fzf-tmux options
#export ZENO_FZF_TMUX_OPTIONS="-p"

# Experimental: Use UNIX Domain Socket
#export ZENO_ENABLE_SOCK=1

# if disable builtin completion
export ZENO_DISABLE_BUILTIN_COMPLETION=1

# default
export ZENO_GIT_CAT="cat" # already aliased to bat
# git file preview with color
#export ZENO_GIT_CAT="bat --color=always"

# default
export ZENO_GIT_TREE="tree" # already aliased to exa
# git folder preview with color
#export ZENO_GIT_TREE="exa --tree"
