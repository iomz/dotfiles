#!/usr/bin/env zsh
#
# Environmental values not in .zshenv
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
if [[ -z "${TINY_CHEZMOI}" ]]; then # not TINY_CHEZMOI
    # fallback if snippet not matched (default: self-insert)
    export ZENO_AUTO_SNIPPET_FALLBACK=self-insert

    # fallback if completion not matched
    # (default: fzf-completion if exists; otherwise expand-or-complete)
    export ZENO_COMPLETION_FALLBACK=expand-or-complete

    # zeno config path
    export ZENO_HOME=${XDG_CONFIG_HOME}/zeno

    # disable zeno cache command when plugin loaded
    export ZENO_DISABLE_EXECUTE_CACHE_COMMAND=1

    # enable fzf-tmux
    export ZENO_ENABLE_FZF_TMUX=1

    # set fzf-tmux options
    export ZENO_FZF_TMUX_OPTIONS="-p"

    # experimental: use UNIX Domain Socket
    #export ZENO_ENABLE_SOCK=1

    # disable builtin completion
    export ZENO_DISABLE_BUILTIN_COMPLETION=1

    # may get overwritten in 20-alias.zsh
    export ZENO_GIT_CAT="cat"

    # may get overwritten in 20-alias.zsh
    export ZENO_GIT_TREE="tree"
fi
# }}}


# zsh-autosuggestions {{{
export ZSH_AUTOSUGGEST_USE_ASYNC=1
export ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=#00ffff,bold,underline'
ZSH_AUTOSUGGEST_CLEAR_WIDGETS+=(accept-line)
# }}}
