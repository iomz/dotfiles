bindkey "$terminfo[kcbt]" reverse-menu-complete

# edit command line with $EDITOR
autoload -Uz edit-command-line
zle -N edit-command-line
bindkey '^xe'  edit-command-line
bindkey '^x^e' edit-command-line

# Key bindings
bindkey -e

# open nvim with fzf
bindkey -s '^o' 'nvim $(fzf)^M'

zle -N history-beginning-search-backward-end history-search-end
zle -N history-beginning-search-forward-end history-search-end
bindkey '^P' history-beginning-search-backward-end
bindkey '^N' history-beginning-search-forward-end

# zeno
if [[ -n $ZENO_LOADED ]]; then
    bindkey ' '  zeno-auto-snippet;
    bindkey '^m' zeno-auto-snippet-and-accept-line;
    bindkey '^i' zeno-completion;
    bindkey '^g' zeno-ghq-cd; # switch ghq dir
    bindkey '^r' zeno-history-selection; # search history
    bindkey '^x^s' zeno-insert-snippet; # search snippets
    bindkey '^x ' zeno-insert-space; # insert space
fi
