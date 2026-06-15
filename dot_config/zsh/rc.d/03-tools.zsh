#!/usr/bin/env zsh
#
# Zinit-managed tools
# Download and link binaries into $ZPFX.
#

# Tool setup is only needed in real interactive shells.
[[ -o interactive && -t 0 ]] || return

# TINY_CHEZMOI
if [[ -n "${TINY_CHEZMOI}" ]]; then
    zinit from'gh-r' lbin'!' light-mode no'compile' for \
        compile'key-bindings.zsh' \
        dl="$(builtin print -c -- https://raw.githubusercontent.com/junegunn/fzf/refs/heads/master/{shell/{'key-bindings.zsh;','completion.zsh -> _fzf;'},'man/man1/fzf.1 -> $ZPFX/share/man/man1/fzf.1;'})" \
        lbin'!fzf;' \
        src'key-bindings.zsh' \
        @junegunn/fzf \
        @x-motemen/ghq
else
    # GitHub {{{
    zinit from'gh-r' lbin'!' light-mode no'compile' for \
        @sharkdp/bat \
        lbin'!bat-modules;!batdiff;!batgrep;!batman;!batpipe;!batwatch;!prettybat;' \
        @eth-p/bat-extras \
        @dandavison/delta \
        @muesli/duf \
        @bootandy/dust \
        cp'**/exa.zsh->_exa' \
        @ogham/exa \
        compile'key-bindings.zsh' \
        dl="$(builtin print -c -- https://raw.githubusercontent.com/junegunn/fzf/refs/heads/master/{shell/{'key-bindings.zsh;','completion.zsh -> _fzf;'},'man/man1/fzf.1 -> $ZPFX/share/man/man1/fzf.1;'})" \
        lbin'!fzf;' \
        src'key-bindings.zsh' \
        @junegunn/fzf \
        @sharkdp/fd \
        @Songmu/ghg \
        @x-motemen/ghq \
        @sharkdp/hyperfine \
        lbin'!rg' \
        @BurntSushi/ripgrep \
        @r-darwish/topgrade \
        @atanunq/viu
    # }}}
fi
