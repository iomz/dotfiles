#!/usr/bin/env zsh
#
# Temporary Zinit-managed tools
#

[[ -o interactive && -t 0 ]] || return
[[ -n "${TINY_CHEZMOI}" ]] && return

# Keep this file intentionally small.
# Prefer mise or brew for CLI binaries.
