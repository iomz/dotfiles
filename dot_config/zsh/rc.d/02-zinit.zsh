#!/usr/bin/env zsh
#
# Zinit
#

# Initialize Zinit {{{
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


# zeno.zsh {{{
if [[ -z "${LIGHT_CHEZMOI}" ]]; then # not LIGHT_CHEZMOI
    zinit lucid depth'1' blockf for \
        @yuki-yano/zeno.zsh
fi
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
    atpull'zinit creinstall -q .' blockf \
    atinit'fpath=(${XDG_DATA_HOME}/zinit/completions $fpath)' \
    @zsh-users/zsh-completions \
    atload"_zsh_autosuggest_start" \
    @zsh-users/zsh-autosuggestions \
    atclone'(){local f;cd -q →*;for f (*~*.zwc){zcompile -Uz -- ${f}};}' \
    atpull'%atclone' \
    compile'.*fast*~*.zwc' \
    nocompletions \
    @zdharma-continuum/fast-syntax-highlighting
# }}}


# compinit {{{
#zinit lucid wait'0b' for \
    #    as'null' atload'<do something>' \
    #    id-as'init-zinit' \
    #    nocd \
    #    @zdharma-continuum/null
# }}}


# miscellaneous {{{
zinit light-mode for \
    @chriskempson/base16-shell \
    @iomz/emoji-cli \
    @woefe/git-prompt.zsh \
    @romkatv/zsh-prompt-benchmark \
    @agkozak/zsh-z
# }}}
