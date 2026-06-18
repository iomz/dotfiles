#!/usr/bin/env zsh
#
# Shell hooks
#

[[ -o interactive && -t 0 ]] || return

# direnv
if whence direnv >/dev/null 2>&1; then
    eval "$(direnv hook zsh)"
fi

# GnuPG
if whence gpg-connect-agent >/dev/null 2>&1; then
    export GPG_TTY="$(tty)"
    gpg-connect-agent updatestartuptty /bye >/dev/null 2>&1 || true
fi
