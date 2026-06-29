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

# fzf zle widgets
bind_widget_if_exists '^ ' fzf-insert-file-path-widget
bind_widget_if_exists '^o' fzf-edit-widget
bind_widget_if_exists '^x^o' fzf-edit-all-widget

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

# Useful explicit zeno widgets.
bind_widget_if_exists '^g' zeno-ghq-cd
bind_widget_if_exists '^r' zeno-history-selection

# Keep core editing keys on plain zsh defaults.
# zeno-completion / auto-snippet widgets break redraw on Linux.
# bindkey '^i' expand-or-complete
bindkey ' ' self-insert
bindkey '^m' .accept-line

# Disabled until their behavior is understood.
# bind_widget_if_exists '^I' zeno-completion
# bind_widget_if_exists $'\e[105;5u' zeno-completion
# bind_widget_if_exists '^S' zeno-insert-snippet
# bind_widget_if_exists '^Xz' zeno-toggle-auto-snippet

# }}}

# zsh-autosuggestions {{{
bind_widget_if_exists '^_' autosuggest-execute
bind_widget_if_exists '^ ' autosuggest-accept
# }}}

# Shift+Enter inserts a literal newline instead of accepting the command line. {{{
bind_widget_if_exists $'\e[13;2u' insert-line-break
bind_widget_if_exists $'\e[13;2~' insert-line-break
bind_widget_if_exists $'\e[27;2;13~' insert-line-break
# }}}
