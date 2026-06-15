#!/usr/bin/env zsh
#
# Shell hooks
#

[[ -o interactive && -t 0 ]] || return

# direnv
if whence direnv >/dev/null 2>&1; then
    eval "$(direnv hook zsh)"
fi
