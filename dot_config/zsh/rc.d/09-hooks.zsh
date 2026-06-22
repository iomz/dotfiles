#!/usr/bin/env zsh
#
# Shell hooks
#

[[ -o interactive && -t 0 ]] || return

autoload -Uz add-zsh-hook

# direnv
if whence direnv >/dev/null 2>&1; then
    eval "$(direnv hook zsh)"
fi

# GnuPG
if whence gpg-connect-agent >/dev/null 2>&1; then
    export GPG_TTY="$(tty)"
    gpg-connect-agent updatestartuptty /bye >/dev/null 2>&1 || true
fi

# History
_zsh_history_filter() {
    builtin emulate -L zsh

    local line="${1%$'\n'}"
    local max_length=500

    if (( ${#line} > max_length )); then
        return 1
    fi

    return 0
}

add-zsh-hook zshaddhistory _zsh_history_filter
