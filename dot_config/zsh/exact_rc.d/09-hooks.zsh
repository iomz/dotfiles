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

# Prevent cmux from inheriting the previous path in new tabs/windows
# Disable this inside zellij because zellij pane/session cwd handling should win.
if [[ -z "${ZELLIJ:-}" ]] && { [[ -n "${CMUX_WORKSPACE_ID:-}" ]] || [[ -n "${CMUX_SOCKET:-}" ]]; }; then
  # Reset to home directory only on initial shell session creation.
  # This avoids resetting the path when splitting panes by checking SHLVL.
  if [ "$SHLVL" -eq 1 ] || [ "$SHLVL" -eq 2 ]; then
    cd ~
  fi
fi

