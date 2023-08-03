#!/usr/bin/env zsh
#
# Sets bindkeys
#

# emacs style (instead of -v)
bindkey -e
#
#"^A" beginning-of-line
#"^B" backward-char
#"^C" SIGINT
#"^E" end-of-line
#"^F" forward-char
#"^H" backward-delete-char
#"^J" accept-line
#"^K" kill-line
#"^L" clear-screen
#"^N" down-line-or-history
#"^P" up-line-or-history
#"^T" fzf-file-widget
#"^U" kill-whole-line
#"^V" quoted-insert
#"^W" backward-kill-word

# back-tab key
bindkey "$terminfo[kcbt]" reverse-menu-complete

# edit command line with $EDITOR
autoload -Uz edit-command-line
zle -N edit-command-line
bindkey '^XE'  edit-command-line
bindkey '^X^E' edit-command-line

# emoji-cli
zle -N emoji::cli
bindkey '^H' emoji::cli

# open nvim with fzf
# The -s flag to bindkey specifies that you are binding the key to a string, not a command.
bindkey -s '^O' '$EDITOR $(fzf)^J'

# menu select
bindkey -M menuselect '^H' undo
bindkey -M menuselect '^N' down-line-or-history
bindkey -M menuselect '^P' up-line-or-history
bindkey -M menuselect 'H' vi-backward-char
bindkey -M menuselect 'J' vi-down-line-or-history
bindkey -M menuselect 'K' vi-up-line-or-history
bindkey -M menuselect 'L' vi-forward-char

# zeno.zsh {{{
if [[ -n $ZENO_LOADED ]]; then
    bindkey -M isearch ' ' self-insert
    bindkey ' ' zeno-auto-snippet
    bindkey '^I' zeno-completion
    bindkey '^G' zeno-ghq-cd # switch ghq dir
    bindkey '^M' zeno-auto-snippet-and-accept-line
    #bindkey '^R' zeno-history-selection # search history
    bindkey '^S' zeno-insert-snippet # search snippets
    #bindkey '^X ' zeno-insert-space # insert space
    #bindkey '^X^M' accept-line
    bindkey '^Xz' zeno-toggle-auto-snippet
fi
# }}}

# zsh-autosuggestions {{{
bindkey '^_' autosuggest-execute
bindkey '^ ' autosuggest-accept
# }}}
