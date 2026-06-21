#!/usr/bin/env zsh
#
# Styles
#

[[ -o interactive && -t 0 ]] || return


# Colors {{{
export TERM=xterm-256color

autoload -Uz colors
colors

typeset -gAH FG BG
for c in {000..255}; do
    FG[$c]="%{\e[38;5;${c}m%}"
    BG[$c]="%{\e[48;5;${c}m%}"
done

typeset -ga IOMZ_COLORS=(
    $'%{\e[38;5;190m%}'   # yellow
    $'%{\e[38;5;166m%}'   # brown red
    $'%{\e[38;5;074m%}'   # cyan
    $'%{\e[38;5;001m%}'   # magenta
    $'%{\e[38;5;027m%}'   # blue
    $'%{\e[38;5;012m%}'   # pale purple
    $'%{\e[38;5;033m%}'   # ocean blue
    $'%{\e[38;5;129m%}'   # purple
    $'%{\e[38;5;125m%}'   # red
    $'%{\e[38;5;046m%}'   # green
    $'%{\e[38;5;118m%}'   # lime green
)

typeset -g DEFAULT=%{$reset_color%}
typeset -g YELLOW=$IOMZ_COLORS[1]
typeset -g BROWN_RED=$IOMZ_COLORS[2]
typeset -g CYAN=$IOMZ_COLORS[3]
typeset -g MAGENTA=$IOMZ_COLORS[4]
typeset -g BLUE=$IOMZ_COLORS[5]
typeset -g PALE_PURPLE=$IOMZ_COLORS[6]
typeset -g OCEAN_BLUE=$IOMZ_COLORS[7]
typeset -g PURPLE=$IOMZ_COLORS[8]
typeset -g RED=$IOMZ_COLORS[9]
typeset -g GREEN=$IOMZ_COLORS[10]
typeset -g LIME_GREEN=$IOMZ_COLORS[11]
typeset -g GREY=$'%{\e[38;5;008m%}'

typeset -g ZSH_SPECTRUM_TEXT=${ZSH_SPECTRUM_TEXT:-Arma virumque cano Troiae qui primus ab oris}

spectrum_ls() {
    local code

    for code in {1..${#IOMZ_COLORS}}; do
        print -P -- "$code: ${IOMZ_COLORS[$code]}${ZSH_SPECTRUM_TEXT}%{$reset_color%}"
    done
}

spectrum_all() {
    local code

    for code in {000..255}; do
        print -P -- "$code: ${FG[$code]}${ZSH_SPECTRUM_TEXT}%{$reset_color%}"
    done
}
# }}}


# Prompt {{{
# Prefer Starship when available. Fall back to Pure for full interactive shells.
# Tiny setup avoids plugin-managed prompts.
if [[ -n "${TINY_CHEZMOI}" ]]; then
    PROMPT='%n@%m:%~ %# '
elif command -v starship >/dev/null 2>&1; then
    eval "$(starship init zsh)"
elif (( ${+functions[zinit]} )); then
    eval "MODE_CURSOR_"{'SEARCH="#ff00ff blinking underline"','VICMD="green block"','VIINS="#ffff00  bar"'}";"

    PURE_GIT_DOWN_ARROW='%1{↓%}'
    PURE_GIT_UP_ARROW='%1{↑%}'
    PURE_PROMPT_SYMBOL="${HOST} ᐳ"
    PURE_PROMPT_VICMD_SYMBOL="${HOST} ᐸ"

    zstyle ':prompt:pure:git:action' color 'yellow'
    zstyle ':prompt:pure:git:branch' color 'blue'
    zstyle ':prompt:pure:git:dirty' color 'red'
    zstyle ':prompt:pure:path' color 'cyan'
    zstyle ':prompt:pure:prompt:success' color 'green'

    zinit for \
        light-mode \
        compile'(async|pure).zsh' \
        multisrc'(async|pure).zsh' \
        @sindresorhus/pure
else
    PROMPT='%n@%m:%~ %# '
fi
# }}}


# ZLE highlight {{{
zle_highlight=('paste:fg=white,bg=black')
# }}}


# Pager {{{
man() {
    env \
        LESS_TERMCAP_mb=$(printf "\e[1;31m") \
        LESS_TERMCAP_md=$(printf "\e[1;31m") \
        LESS_TERMCAP_me=$(printf "\e[0m") \
        LESS_TERMCAP_se=$(printf "\e[0m") \
        LESS_TERMCAP_so=$(printf "\e[1;44;33m") \
        LESS_TERMCAP_ue=$(printf "\e[0m") \
        LESS_TERMCAP_us=$(printf "\e[1;32m") \
        command man "$@"
}
# }}}


# Stderr color {{{
# Disabled by default because it can corrupt TUI/ZLE output.
if [[ -n "${COLOR_STDERR}" ]]; then
    zmodload zsh/terminfo zsh/system

    color_stderr() {
        local std_err_color

        while sysread std_err_color; do
            syswrite -o 2 "${fg_bold[red]}${std_err_color}${terminfo[sgr0]}"
        done
    }

    exec 2> >(color_stderr)
fi
# }}}