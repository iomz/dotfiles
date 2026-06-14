#!/usr/bin/env zsh
#
# zeno.zsh
#
# zeno.zsh is powered by Deno. Deno is managed by mise, so this file must run
# after mise activation.

[[ -o interactive && -t 0 ]] || return
[[ -n "${TINY_CHEZMOI}" ]] && return

# fallback if snippet not matched (default: self-insert)
export ZENO_AUTO_SNIPPET_FALLBACK=self-insert

# fallback if completion not matched
# (default: fzf-completion if exists; otherwise expand-or-complete)
export ZENO_COMPLETION_FALLBACK=expand-or-complete

# zeno config path
export ZENO_HOME=${XDG_CONFIG_HOME}/zeno

# disable zeno cache command when plugin loaded
export ZENO_DISABLE_EXECUTE_CACHE_COMMAND=1

# enable fzf-tmux
export ZENO_ENABLE_FZF_TMUX=1

# set fzf-tmux options
export ZENO_FZF_TMUX_OPTIONS="-p"

# experimental: use UNIX Domain Socket
#export ZENO_ENABLE_SOCK=1

# disable builtin completion
export ZENO_DISABLE_BUILTIN_COMPLETION=1

# may get overwritten in 20-aliases.zsh
export ZENO_GIT_CAT="cat"

# may get overwritten in 20-aliases.zsh
export ZENO_GIT_TREE="tree"

if ! command -v zinit >/dev/null 2>&1; then
    log::error 'zeno.zsh skipped: zinit not found'
    return
fi

if ! command -v deno >/dev/null 2>&1; then
    log::error 'zeno.zsh skipped: deno not found'
    return
fi

zinit lucid depth'1' blockf for \
    @yuki-yano/zeno.zsh
