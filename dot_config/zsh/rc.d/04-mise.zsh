#!/usr/bin/env zsh
#
# mise
#

# Prefer mise-managed shims/tools over asdf shims when mise is installed.
if command -v mise > /dev/null; then
    path=(${MISE_DATA_DIR:-${XDG_DATA_HOME}/mise}/shims(N-/) $path)
    eval "$(mise activate zsh)"
fi
