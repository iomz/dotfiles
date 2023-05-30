#!/usr/bin/env zsh
#
# Styles
#

# Colors {{{
export TERM=xterm-256color
typeset -AHg FG BG
autoload -U colors && colors
for c in {000..255}; do
    FG[$c]="%{\e[38;5;${c}m%}"
    BG[$c]="%{\e[48;5;${c}m%}"
done
colors=(
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
local DEFAULT=%{$reset_color%}
local YELLOW=$colors[1]
local BROWN_RED=$colors[2]
local CYAN=$colors[3]
local MAGENTA=$colors[4]
local BLUE=$colors[5]
local PALE_PURPLE=$colors[6]
local OCEAN_BLUE=$colors[7]
local PURPLE=$colors[8]
local RED=$colors[9]
local GREEN=$colors[10]
local LIME_GREEN=$colors[11]
# extra
local GREY=$'%{\e[38;5;008m%}'

# Show all 256 colors with color number
local ZSH_SPECTRUM_TEXT=${ZSH_SPECTRUM_TEXT:-Arma virumque cano Troiae qui primus ab oris}
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

## stderr in red {{{
zmodload zsh/terminfo zsh/system
color_stderr() {
    while sysread std_err_color; do
        syswrite -o 2 "${fg_bold[red]}${std_err_color}${terminfo[sgr0]}"
    done
}
exec 2> >(color_stderr)
## }}}

# }}}


# compinit {{{
autoload -U compinit && compinit

## colors {{{
#zstyle ':completion:*' list-colors 'di=36' 'ln=35'
#zstyle ':completion:*' list-separator '-->'
#zstyle ':completion:*' format ${OCEAN_BLUE}' -- %d -- '$DEFAULT
zstyle ':completion:*:default' list-colors ${(s.:.)colors}
zstyle ':completion:*:corrections' format $MAGENTA' -- %d (errors: %e) -- '$DEFAULT
zstyle ':completion:*:descriptions' format ' -- '$YELLOW'Completing %B%d%b -- '$DEFAULT
zstyle ':completion:*:commands' list-colors '=*=1;31'
zstyle ':completion:*:builtins' list-colors '=*=1;38;5;142'
zstyle ':completion:*:messages' format $PURPLE' -- %d -- '$DEFAULT
zstyle ':completion:*:options' list-colors '=*=32' # green
zstyle ':completion:*:options' list-colors '=^(-- *)=34'
zstyle ':completion:*:parameters' list-colors '=*=32' # green
zstyle ':completion:*:warnings' format ${BROWN_RED}'No matches for: '$RED'%d'$DEFAULT
#zstyle ':completion:*:warnings' format ${BROWN_RED}' -- no matches found --'$DEFAULT
zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#) ([0-9a-z-]#)*=01;36=0=01'
#zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([%0-9]#)*=0=01;31'

## }}}

#zstyle '*' single-ignored show
#
zstyle ':completion:*' completer _expand _complete _match _prefix _approximate _list
zstyle ':completion:*' group-name ''
#zstyle ':completion:*' matcher-list '' 'm:{a-z}={A-Z}' '+m:{A-Z}={a-z}'
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'
zstyle ':completion:*' squeeze-slashes true
zstyle ':completion:*' verbose yes

zstyle ':completion:*:approximate:*' max-errors 1 numeric
#zstyle -e ':completion:*:approximate:*' max-errors 'reply=($((($#PREFIX+$#SUFFIX)/3))numeric)'
zstyle ':completion:*:complete:*' cache-path "${ZDOTDIR:-$HOME}/.zcompcache"
zstyle ':completion:*:complete:*' use-cache on
zstyle ':completion:*:default' menu select=2
zstyle ':completion:*:default' list-prompt '%S%M matches%s'
zstyle ':completion:*:functions' ignored-patterns '(_*|pre(cmd|exec))'
zstyle ':completion:*:manuals' separate-sections true
zstyle ':completion:*:manuals.(^1*)' insert-sections true
zstyle ':completion:*:match:*' original only
zstyle ':completion:*:matches' group 'yes'
#zstyle ':completion:*:messages' format ' %F{purple} -- %d --%f'
zstyle ':completion:*:options' description 'yes'
zstyle ':completion:*:sudo:*' command-path /usr/local/sbin /usr/local/bin /usr/sbin /usr/bin /sbin /bin

#zstyle ':completion:*:(rm|kill|diff):*' ignore-line other

zstyle ':completion:*:complete:*' use-cache true

zstyle ':completion:*:options' auto-description '%d'
zstyle ':completion:*:options' description 'yes'
zstyle ':completion:*:rm:*' file-patterns '*:all-files'
zstyle ':completion::*:(-command-|export):*' fake-parameters ${${${_comps[(I)-value-*]#*,}%%,*}:#-*-}
zstyle ':completion:*:-tilde-:*' group-order 'named-directories' 'path-directories' 'users' 'expand'


zstyle ':completion:*:*:cd:*' tag-order local-directories directory-stack path-directories
zstyle ':completion:*:*:cd:*:directory-stack' menu yes select

zstyle ':completion:*:*:kill:*' force-list always
zstyle ':completion:*:*:kill:*' insert-ids single
zstyle ':completion:*:*:kill:*' menu yes select
zstyle ':completion:*:*:-command-:*:*' group-order functions builtins commands
zstyle ':completion:*:*:-subscript-:*' tag-order indexes parameters

# ssh/scp/rsync {{
zstyle ':completion:*:ssh:*' group-order hosts-host hosts-ipaddr
zstyle ':completion:*:ssh:*' tag-order 'hosts:-host:host hosts:-ipaddr:ip\ address *'
zstyle ':completion:*:(scp|rsync):*' group-order files all-files hosts-host hosts-ipaddr
zstyle ':completion:*:(scp|rsync):*' tag-order 'hosts:-host:host hosts:-ipaddr:ip\ address *'
zstyle ':completion:*:(ssh|scp|rsync):*:hosts-domain' ignored-patterns '<->.<->.<->.<->' '^[-[:alnum:]]##(.[-[:alnum:]]##)##' '*@*'
zstyle ':completion:*:(ssh|scp|rsync):*:hosts-host' ignored-patterns '*(.|:)*' loopback ip6-loopback localhost ip6-localhost broadcasthost
zstyle ':completion:*:(ssh|scp|rsync):*:hosts-ipaddr' ignored-patterns '^(<->.<->.<->.<->|(|::)([[:xdigit:].]##:(#c,2))##(|%*))' '127.0.0.<->' '255.255.255.255' '::1' 'fe80::*'

## populate hostname completion.
#zstyle -e ':completion:*:hosts' hosts 'reply=(
#${=${=${=${${(f)"$(cat {/etc/ssh_,~/.ssh/known_}hosts(|2)(N) 2>/dev/null)"}%%[#| ]*}//\]:[0-9]*/ }//,/ }//\[/ }
#${=${(f)"$(cat /etc/hosts(|)(N) <<(ypcat hosts 2>/dev/null))"}%%\#*}
#)'
zstyle -e ':completion:*:hosts' hosts 'reply=(${=${${${${(@M)${(f)"$(cat ~/.ssh/config 2>/dev/null)"}:#Host *}#Host }:#*\**}:#*\?*}})'

## don't complete uninteresting users...
zstyle ':completion:*:*:*:users' ignored-patterns \
    adm amanda apache avahi beaglidx bin cacti canna clamav daemon \
    dbus distcache dovecot fax ftp games gdm gkrellmd gopher \
    hacluster haldaemon halt hsqldb ident junkbust ldap lp mail \
    mailman mailnull mldonkey mysql nagios \
    named netdump news nfsnobody nobody nscd ntp nut nx openvpn \
    operator pcap postfix postgres privoxy pulse pvm quagga radvd \
    rpc rpcuser rpm shutdown squid sshd sync uucp vcsa xfs '_*'
# }}}

zstyle ':completion:*:*:*:*:processes' command 'ps -u $LOGNAME -o pid,user,command -w'
zstyle ':completion:*:*:*:*:*' ignore-line 'yes'
zstyle ':completion:*:*:*:*:*' menu select

# }}}
