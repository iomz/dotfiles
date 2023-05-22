#!/usr/bin/env zsh
#
# Zinit
#

# Initialize Zinit {{{
#
typeset -gAH ZI=(HOME_DIR "${XDG_DATA_HOME}/zinit")
ZI+=(
    BIN_DIR "$ZI[HOME_DIR]"/zinit.git
    BRANCH 'main'
    COMPINIT_OPTS '-C'
    COMPLETIONS_DIR "$ZI[HOME_DIR]"/completions
    # OPTIMIZE_OUT_OF_DISK_ACCESSES "1"
    PLUGINS_DIR "$ZI[HOME_DIR]"/plugins
    SNIPPETS_DIR "$ZI[HOME_DIR]"/snippets
    SRC 'zdharma-continuum'
    ZCOMPDUMP_PATH "$ZI[HOME_DIR]"/zcompdump
    ZPFX "$ZI[HOME_DIR]"/polaris
)
mkdir -p "$ZI[ZCOMPDUMP_PATH]" || true
if [[ ! -e $ZI[BIN_DIR]/zinit.zsh ]]; then
    {
        log::info 'downloading zinit'
        command git clone \
            --branch ${ZI[BRANCH]:-main} \
            https://github.com/${ZI[FORK]:-${ZI[SRC]}}/zinit.git \
            ${ZI[BIN_DIR]}
        log::info 'setting up zinit'
        command chmod g-rwX ${ZI[HOME_DIR]} && \
            zcompile "${ZI[BIN_DIR]}/zinit.zsh"
        log::info 'installed zinit'
    } || log::error 'failed to download zinit'
fi
if [[ -e ${ZI[BIN_DIR]}/zinit.zsh ]]; then
    typeset -gAH ZINIT=(${(kv)ZI})
    builtin source ${ZINIT[BIN_DIR]}/zinit.zsh && \
        autoload _zinit && \
        (( ${+_comps} )) && \
        _comps[zinit]=_zinit
else
    log::error 'failed to find zinit installation'
fi
# }}}

# Static zsh binary {{{
#
# zinit for atpull"%atclone" depth"1" lucid nocompile nocompletions as"null" \
    #     atclone"./install -e no -d ~/.local" atinit"export PATH=$HOME/.local/bin:$PATH" \
    #   @romkatv/zsh-bin
# }}}

# Snippets {{{
#
local GH_RAW_URL='https://raw.githubusercontent.com'
znippet() {
    zinit for \
        as'completion' \
        depth'1' \
        has"${1}" \
        is-snippet \
        light-mode \
        nocompile \
        "${GH_RAW_URL}/${2}/_${1}";
}
znippet 'brew'   'Homebrew/brew/master/completions/zsh'
znippet 'docker' 'docker/cli/master/contrib/completion/zsh'
znippet 'exa'    'ogham/exa/master/completions/zsh'
znippet 'fd'     'sharkdp/fd/master/contrib/completion'
zinit as'completion' id-as'auto' is-snippet light-mode for \
    "${GH_RAW_URL}/git/git/master/contrib/completion/git-completion.zsh" \
    "${GH_RAW_URL}/Homebrew/homebrew-services/master/completions/zsh/_brew_services"
# }}}

# Prompt {{{
# For a minmal prompt
#(( MINIMAL )) || {
#    eval "MODE_CURSOR_"{'SEARCH="#ff00ff blinking underline"','VICMD="green block"','VIINS="#ffff00  bar"'}";"
#    zinit for light-mode compile'(async|pure).zsh' multisrc'(async|pure).zsh' atinit"
#    PURE_GIT_DOWN_ARROW='%1{↓%}'; PURE_GIT_UP_ARROW='%1{↑%}'
#    PURE_PROMPT_SYMBOL='${HOST}%2{ ᐳ%}'; PURE_PROMPT_VICMD_SYMBOL='${HOST}%2{ ᐸ%}'
#    zstyle ':prompt:pure:git:action' color 'yellow'
#    zstyle ':prompt:pure:git:branch' color 'blue'
#    zstyle ':prompt:pure:git:dirty' color 'red'
#    zstyle ':prompt:pure:path' color 'cyan'
#    zstyle ':prompt:pure:prompt:success' color 'green'" \
    #        @sindresorhus/pure
#}
# }}}

# Annexes {{{
# Load zinit-annex
zinit id-as'auto' for @"${ZI[SRC]}/zinit-annex-"{'linkman','patch-dl','submods','binary-symlink','bin-gem-node'}
# }}}

# GitHub binaries {{{
# Download and link binaries available on GitHub
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
    @sharkdp/hyperfine \
    lbin'!nvim' \
    ver'nightly' \
    @neovim/neovim \
    @r-darwish/topgrade
# }}}

# zeno.zsh {{{
zinit lucid depth'1' blockf for \
    @yuki-yano/zeno.zsh
# }}}

# unit testing {{{
zinit light-mode for \
    compile \
    @vladdoster/plugin-zinit-aliases \
    atinit'bindkey -M vicmd "^v" edit-command-line' \
    @softmoth/zsh-vim-mode \
    as'null' \
    lbin'!build/zsd*' \
    make'--always-make' \
    @zdharma-continuum/zshelldoc \
    atclone'./build.zsh' \
    as'null' \
    lbin'!' \
    @zdharma-continuum/zunit
# }}}

# Highlight {{{
zle_highlight=('paste:fg=white,bg=black')
zinit wait'0a' lucid for \
    has'svn' svn submods'zsh-users/zsh-history-substring-search -> external' \
    @OMZ::plugins/history-substring-search \
    atpull'zinit creinstall -q .' blockf \
    @zsh-users/zsh-completions \
    atinit" \
    ZSH_AUTOSUGGEST_USE_ASYNC=1; \
    ZSH_AUTOSUGGEST_CLEAR_WIDGETS+=(accept-line); \
    ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=#ff00ff,bg=cyan,bold,underline' \
    bindkey '^_' autosuggest-execute; \
    bindkey '^ ' autosuggest-accept;" \
    atload"_zsh_autosuggest_start" \
    @zsh-users/zsh-autosuggestions \
    atclone'(){local f;cd -q →*;for f (*~*.zwc){zcompile -Uz -- ${f}};}' \
    atpull'%atclone' \
    compile'.*fast*~*.zwc' \
    nocompletions \
    @zdharma-continuum/fast-syntax-highlighting
# }}}

# null {{{
zinit lucid wait'0b' for \
    as'null' atload'zicompinit; zicdreplay' \
    id-as'init-zinit' \
    nocd \
    @zdharma-continuum/null
zinit light-mode for \
    @chriskempson/base16-shell \
    @iomz/emoji-cli \
    @yukiycino-dotfiles/fancy-ctrl-z \
    @woefe/git-prompt.zsh \
    @romkatv/zsh-prompt-benchmark \
    @agkozak/zsh-z
# }}}
