#!/usr/bin/env zsh
#
# Zinit polaris
# Download and link binaries
#

# For RPi, don't do much
if [[ -e /etc/rpi-issue ]]; then
    zinit from'gh-r' lbin'!' light-mode no'compile' for \
        compile'key-bindings.zsh' \
        dl="$(builtin print -c -- https://raw.githubusercontent.com/junegunn/fzf/master/{shell/{'key-bindings.zsh;','completion.zsh -> _fzf;'},'bin/fzf-tmux -> fzf-tmux;',man/{'man1/fzf.1 -> $ZPFX/share/man/man1/fzf.1;','man1/fzf-tmux.1 -> $ZPFX/share/man/man1/fzf-tmux.1;'}})" \
        lbin'!fzf;!fzf-tmux;' \
        src'key-bindings.zsh' \
        @junegunn/fzf \
        @x-motemen/ghq
    return
fi

# GitHub {{{
zinit from'gh-r' lbin'!' light-mode no'compile' for \
    @sharkdp/bat \
    lbin'!bat-modules;!batdiff;!batgrep;!batman;!batpipe;!batwatch;!prettybat;' \
    @eth-p/bat-extras \
    @dandavison/delta \
    cp'**/exa.zsh->_exa' \
    @ogham/exa \
    compile'key-bindings.zsh' \
    dl="$(builtin print -c -- https://raw.githubusercontent.com/junegunn/fzf/master/{shell/{'key-bindings.zsh;','completion.zsh -> _fzf;'},'bin/fzf-tmux -> fzf-tmux;',man/{'man1/fzf.1 -> $ZPFX/share/man/man1/fzf.1;','man1/fzf-tmux.1 -> $ZPFX/share/man/man1/fzf-tmux.1;'}})" \
    lbin'!fzf;!fzf-tmux;' \
    src'key-bindings.zsh' \
    @junegunn/fzf \
    @Songmu/ghg \
    @x-motemen/ghq \
    @sharkdp/hyperfine \
    lbin'!nvim' \
    ver'nightly' \
    @neovim/neovim \
    @r-darwish/topgrade
# }}}
