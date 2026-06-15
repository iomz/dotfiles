#!/usr/bin/env zsh
#
# Key bindings
#

# Keymaps only exist for interactive ZLE sessions.
[[ -o interactive && -t 0 ]] || return
[[ -o zle ]] || return

bind_widget_if_exists() {
    local key="$1"
    local widget="$2"
    local keymap="${3:-}"

    if (( ${+widgets[$widget]} )); then
        if [[ -n "$keymap" ]]; then
            bindkey -M "$keymap" "$key" "$widget"
        else
            bindkey "$key" "$widget"
        fi
    fi
}

# emacs style (instead of -v)
bindkey -e

# Default Emacs-style key bindings reference {{{
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
# }}}

# open $EDITOR with fzf
bind_widget_if_exists '^o' fzf-edit-widget

# back-tab key
bindkey "$terminfo[kcbt]" reverse-menu-complete

# edit command line with $EDITOR
autoload -Uz edit-command-line
zle -N edit-command-line
bindkey '^xe'  edit-command-line
bindkey '^x^e' edit-command-line

# emoji-cli
if whence emoji::cli >/dev/null 2>&1; then
    zle -N emoji::cli
    bind_widget_if_exists '^h' emoji::cli
fi

# menu select {{{
#bindkey -M menuselect '^H' undo
#bindkey -M menuselect '^N' down-line-or-history
#bindkey -M menuselect '^P' up-line-or-history
#bindkey -M menuselect 'H' vi-backward-char
#bindkey -M menuselect 'J' vi-down-line-or-history
#bindkey -M menuselect 'K' vi-up-line-or-history
#bindkey -M menuselect 'L' vi-forward-char
# }}}

# zeno.zsh {{{
if [[ -n $ZENO_LOADED ]]; then
    bindkey -M isearch ' ' self-insert
    bind_widget_if_exists ' ' zeno-auto-snippet
    bind_widget_if_exists '^i' zeno-completion
    bind_widget_if_exists '^g' zeno-ghq-cd # switch ghq dir
    bind_widget_if_exists '^m' zeno-auto-snippet-and-accept-line
    #bind_widget_if_exists '^r' zeno-history-selection # search history
    bind_widget_if_exists '^s' zeno-insert-snippet # search snippets
    #bind_widget_if_exists '^x ' zeno-insert-space # insert space
    #bindkey '^x^m' accept-line
    bind_widget_if_exists '^xz' zeno-toggle-auto-snippet
fi
# }}}

# zsh-autosuggestions {{{
bind_widget_if_exists '^_' autosuggest-execute
bind_widget_if_exists '^ ' autosuggest-accept
# }}}
