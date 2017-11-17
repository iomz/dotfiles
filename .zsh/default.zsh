# Color
export TERM=xterm-256color
typeset -AHg FG BG
for c in {000..255}; do
    FG[$c]="%{\e[38;5;${c}m%}"
    BG[$c]="%{\e[48;5;${c}m%}"
done
autoload -U colors && colors
colors=(
    $'%{\e[38;5;3m%}'   # yellow
    $'%{\e[38;5;9m%}'   # brown red
    $'%{\e[38;5;6m%}'   # cyan
    $'%{\e[38;5;5m%}'   # magenta
    $'%{\e[38;5;4m%}'   # blue
    $'%{\e[38;5;111m%}' # pale purple
    $'%{\e[38;5;27m%}'  # ocean blue
    $'%{\e[38;5;129m%}' # purple
    $'%{\e[38;5;1m%}'   # red
    $'%{\e[38;5;2m%}'   # green
    $'%{\e[38;5;113m%}' # lime green
)
## stderr in red
zmodload zsh/terminfo zsh/system
color_stderr() {
  while sysread std_err_color; do
    syswrite -o 2 "${fg_bold[red]}${std_err_color}${terminfo[sgr0]}"
  done
}
exec 2> >(color_stderr)
## Show all 256 colors with color number
ZSH_SPECTRUM_TEXT=${ZSH_SPECTRUM_TEXT:-Arma virumque cano Troiae qui primus ab oris}
function spectrum_ls() {
  for code in {1..${#colors}}; do
    print -P -- "$code: $colors[$code]$ZSH_SPECTRUM_TEXT%{$reset_color%}"
  done
}
function spectrum_all() {
  for code in {000..255}; do
    print -P -- "$code: %{$FG[$code]%}$ZSH_SPECTRUM_TEXT%{$reset_color%}"
  done
}
## Dircolors
if [ -f ~/.dircolors ]; then
    if type dircolors > /dev/null 2>&1; then
        eval $(dircolors ~/.dircolors)
    elif type gdircolors > /dev/null 2>&1; then
        eval $(gdircolors ~/.dircolors)
    fi
else
    # It is the default value on OSX, so this line can be omitted
    #export LSCOLORS=exfxcxdxbxegedabagacad
    LSCOLORS=""
    # directory
    LSCOLORS=$LSCOLORS"gx"
    # symboic link
    LSCOLORS=$LSCOLORS"fx"
    # socket
    LSCOLORS=$LSCOLORS"cx"
    # pipe
    LSCOLORS=$LSCOLORS"Fx"
    # executable
    LSCOLORS=$LSCOLORS"ex"
    # block special
    LSCOLORS=$LSCOLORS"ah"
    # character special
    LSCOLORS=$LSCOLORS"bh"
    # executable with setuid bit set
    LSCOLORS=$LSCOLORS"bx"
    # executable with setgid bit set
    LSCOLORS=$LSCOLORS"bx"
    # directory writable to others, with sticky bit
    LSCOLORS=$LSCOLORS"cx"
    # directory writable to others, without sitcky bit
    LSCOLORS=$LSCOLORS"cx"
    export LSCOLORS=$LSCOLORS
fi

# Prompt
colored_time=%{$fg[cyan]%}%T
colored_user=$colors[$((`echo "$USER" | sum | cut -f1 -d' '`%${#colors}))+1]$USER
colored_at=%{$fg[white]%}@
host_name=`hostname | cut -d. -f1`
colored_host=$colors[$((`echo "$host_name" | sum | cut -f1 -d' '`%${#colors}))+1]$host_name
colored_colon=%{$reset_color%}:
colored_path=%{$fg[magenta]%}%~
colored_prompt=%{$reset_color%}%#
PROMPT="${colored_time} ${colored_user}${colored_at}${colored_host}${colored_colon}${colored_path} $colored_prompt "

# Editor
export EDITOR=vim

# Locale
export LC_CTYPE=en_US.UTF-8
export LANG=en_US.UTF-8

