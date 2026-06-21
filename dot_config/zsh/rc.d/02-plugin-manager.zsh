#!/usr/bin/env zsh
#
# Zinit
#

# Skip plugin loading for command-only shells and non-TTY automation.
[[ -o interactive && -t 0 ]] || return

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
    ZCOMPDUMP_DIR "$ZI[HOME_DIR]"/zcompdump
)
mkdir -p "$ZI[ZCOMPDUMP_DIR]" || true
if [[ ! -e $ZI[BIN_DIR]/zinit.zsh ]]; then
    {
        log::info 'downloading zinit'
        command git clone \
            --branch ${ZI[BRANCH]:-main} \
            https://github.com/${ZI[FORK]:-${ZI[SRC]}}/zinit.git \
            ${ZI[BIN_DIR]}
        log::info 'setting up zinit'
        # Avoid insecure completion directory warnings.
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

# Snippets {{{
#
typeset -g GH_RAW_URL='https://raw.githubusercontent.com'

znippet() {
    local command_name=$1
    local snippet_path=$2
    local snippet_url="${GH_RAW_URL}/${snippet_path}/_${command_name}"

    zinit ice \
        as'completion' \
        has"${command_name}" \
        id-as"_${command_name}" \
        light-mode \
        nocompile

    zinit snippet "${snippet_url}"
}

znippet 'docker' 'docker/cli/master/contrib/completion/zsh'
znippet 'fd'     'sharkdp/fd/master/contrib/completion'

zinit ice \
    as'completion' \
    id-as'git-completion.zsh' \
    light-mode

zinit snippet "${GH_RAW_URL}/git/git/master/contrib/completion/git-completion.zsh"
# }}}

# Annexes {{{
# Load only annexes still required by remaining Zinit-managed tools.
zinit id-as'auto' for \
    @"${ZI[SRC]}/zinit-annex-patch-dl" \
    @"${ZI[SRC]}/zinit-annex-binary-symlink"
# }}}

# Editing {{{
zinit light-mode for \
    atinit'bindkey -M vicmd "^v" edit-command-line' \
    @softmoth/zsh-vim-mode
# }}}

# Zsh development {{{
if [[ -n "${ZSH_DEV}" ]]; then
    zinit light-mode for \
        compile \
        @vladdoster/plugin-zinit-aliases \
        as'null' \
        lbin'!build/zsd-*' \
        make'--always-make' \
        @zdharma-continuum/zshelldoc \
        atclone'./build.zsh' \
        as'null' \
        lbin'!' \
        @zdharma-continuum/zunit
fi
[[ -n "${ZSH_BENCH}" ]] && zinit light @romkatv/zsh-prompt-benchmark
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


# miscellaneous {{{
zinit light-mode for \
    @chriskempson/base16-shell \
    @iomz/emoji-cli \
    @woefe/git-prompt.zsh \
    @agkozak/zsh-z
# }}}
