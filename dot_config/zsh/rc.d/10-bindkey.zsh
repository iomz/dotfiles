#!/usr/bin/env zsh
#
# Sets bindkeys
#

# back-tab key
bindkey "$terminfo[kcbt]" reverse-menu-complete

# edit command line with $EDITOR
autoload -Uz edit-command-line
zle -N edit-command-line
bindkey '^xe'  edit-command-line
bindkey '^x^e' edit-command-line

# emacs style (instead of -v)
bindkey -e

# open nvim with fzf
bindkey -s '^o' 'nvim $(fzf)^J'

# history search
bindkey '^p' history-search-backward
bindkey '^n' history-search-forward

# resume with fg (often to nvim)
bindkey '^z' fancy-ctrl-z

# zeno.zsh
#print -- "ZENO_LOADED: ${ZENO_LOADED}"
if [[ -n $ZENO_LOADED ]]; then
    bindkey '^c' zeno-auto-snippet
    bindkey '^i' zeno-completion
    bindkey '^g' zeno-ghq-cd # switch ghq dir
    bindkey '^m' zeno-auto-snippet-and-accept-line
    #bindkey '^r' zeno-history-selection # search history
    bindkey '^x^s' zeno-insert-snippet # search snippets
    bindkey '^x ' zeno-insert-space # insert space
fi
