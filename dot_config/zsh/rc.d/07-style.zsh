#!/usr/bin/env zsh
#
# Styles
#

builtin zstyle ':completion:*:*:-command-:*:*' group-order functions builtins commands
# builtin zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS}
# Use caching to make completion for commands such as dpkg and apt usable.
builtin zstyle ':completion::complete:*' use-cache on
builtin zstyle ':completion::complete:*' cache-path "${ZDOTDIR:-$HOME}/.zcompcache"
builtin zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'
# Group matches and describe.
builtin zstyle ':completion:*:*:*:*:*' menu select
builtin zstyle ':completion:*:matches' group 'yes'
builtin zstyle ':completion:*:options' description 'yes'
builtin zstyle ':completion:*:options' auto-description '%d'
builtin zstyle ':completion:*:corrections' format ' %F{green}-- %d (errors: %e) --%f'
builtin zstyle ':completion:*:descriptions' format ' %F{yellow}-- %d --%f'
builtin zstyle ':completion:*:messages' format ' %F{purple} -- %d --%f'
builtin zstyle ':completion:*:warnings' format ' %F{red}-- no matches found --%f'
builtin zstyle ':completion:*:default' list-prompt '%S%M matches%s'
builtin zstyle ':completion:*' format ' %F{yellow}-- %d --%f'
builtin zstyle ':completion:*' group-name ''
builtin zstyle ':completion:*' verbose yes
# Don't show already completed options in the list
builtin zstyle ':completion:*:*:*:*:*' ignore-line 'yes'
# Fuzzy match mistyped completions.
builtin zstyle ':completion:*' completer _complete _match _approximate
builtin zstyle ':completion:*:match:*' original only
builtin zstyle ':completion:*:approximate:*' max-errors 1 numeric
# Increase the number of errors based on the length of the typed word.
builtin zstyle -e ':completion:*:approximate:*' max-errors 'reply=($((($#PREFIX+$#SUFFIX)/3))numeric)'
# Don't complete unavailable commands.
builtin zstyle ':completion:*:functions' ignored-patterns '(_*|pre(cmd|exec))'
# Array completion element sorting.
builtin zstyle ':completion:*:*:-subscript-:*' tag-order indexes parameters
# Directories
builtin zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS}
builtin zstyle ':completion:*:*:cd:*' tag-order local-directories directory-stack path-directories
builtin zstyle ':completion:*:*:cd:*:directory-stack' menu yes select
builtin zstyle ':completion:*:-tilde-:*' group-order 'named-directories' 'path-directories' 'users' 'expand'
builtin zstyle ':completion:*' squeeze-slashes true
# History
builtin zstyle ':completion:*:history-words' stop yes
builtin zstyle ':completion:*:history-words' remove-all-dups yes
builtin zstyle ':completion:*:history-words' list false
builtin zstyle ':completion:*:history-words' menu yes
# Environmental Variables
builtin zstyle ':completion::*:(-command-|export):*' fake-parameters ${${${_comps[(I)-value-*]#*,}%%,*}:#-*-}
# Populate hostname completion.
# TODO: buggy
#builtin zstyle -e ':completion:*:hosts' hosts 'reply=(
#${=${=${=${${(f)"$(cat {/etc/ssh_,~/.ssh/known_}hosts(|2)(N) 2>/dev/null)"}%%[#| ]*}//\]:[0-9]*/ }//,/ }//\[/ }
#${=${(f)"$(cat /etc/hosts(|)(N) <<(ypcat hosts 2>/dev/null))"}%%\#*}
#${=${${${${(@M)${(f)"$(cat ~/.ssh/config 2>/dev/null)"}:#Host *}#Host }:#*\**}:#*\?*}}
#)'

# Don't complete uninteresting users...
builtin zstyle ':completion:*:*:*:users' ignored-patterns \
    adm amanda apache avahi beaglidx bin cacti canna clamav daemon \
    dbus distcache dovecot fax ftp games gdm gkrellmd gopher \
    hacluster haldaemon halt hsqldb ident junkbust ldap lp mail \
    mailman mailnull mldonkey mysql nagios \
    named netdump news nfsnobody nobody nscd ntp nut nx openvpn \
    operator pcap postfix postgres privoxy pulse pvm quagga radvd \
    rpc rpcuser rpm shutdown squid sshd sync uucp vcsa xfs '_*'
# ... unless we really want to.
builtin zstyle '*' single-ignored show
# Ignore multiple entries.
builtin zstyle ':completion:*:(rm|kill|diff):*' ignore-line other
builtin zstyle ':completion:*:rm:*' file-patterns '*:all-files'
# Kill
builtin zstyle ':completion:*:*:*:*:processes' command 'ps -u $LOGNAME -o pid,user,command -w'
builtin zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#) ([0-9a-z-]#)*=01;36=0=01'
builtin zstyle ':completion:*:*:kill:*' menu yes select
builtin zstyle ':completion:*:*:kill:*' force-list always
builtin zstyle ':completion:*:*:kill:*' insert-ids single
# Man
builtin zstyle ':completion:*:manuals' separate-sections true
builtin zstyle ':completion:*:manuals.(^1*)' insert-sections true
# SSH/SCP/RSYNC
builtin zstyle ':completion:*:(scp|rsync):*' tag-order 'hosts:-host:host hosts:-domain:domain hosts:-ipaddr:ip\ address *'
builtin zstyle ':completion:*:(scp|rsync):*' group-order users files all-files hosts-domain hosts-host hosts-ipaddr
builtin zstyle ':completion:*:ssh:*' tag-order 'hosts:-host:host hosts:-domain:domain hosts:-ipaddr:ip\ address *'
builtin zstyle ':completion:*:ssh:*' group-order users hosts-domain hosts-host users hosts-ipaddr
builtin zstyle ':completion:*:(ssh|scp|rsync):*:hosts-host' ignored-patterns '*(.|:)*' loopback ip6-loopback localhost ip6-localhost broadcasthost
builtin zstyle ':completion:*:(ssh|scp|rsync):*:hosts-domain' ignored-patterns '<->.<->.<->.<->' '^[-[:alnum:]]##(.[-[:alnum:]]##)##' '*@*'
builtin zstyle ':completion:*:(ssh|scp|rsync):*:hosts-ipaddr' ignored-patterns '^(<->.<->.<->.<->|(|::)([[:xdigit:].]##:(#c,2))##(|%*))' '127.0.0.<->' '255.255.255.255' '::1' 'fe80::*'

# --------

#zstyle ':completion:*' completer _expand _complete _match _prefix _approximate _list _history
#zstyle ':completion:*' group-name ''
#zstyle ':completion:*' list-colors 'di=36' 'ln=35'
#zstyle ':completion:*' list-separator '-->'
#zstyle ':completion:*' matcher-list '' 'm:{a-z}={A-Z}' '+m:{A-Z}={a-z}'
#zstyle ':completion:*' verbose yes
#zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([%0-9]#)*=0=01;31'
#zstyle ':completion:*:default' menu select=1
#zstyle ':completion:*:descriptions' format '%F{YELLOW}completing %B%d%b'$DEFAULT
#zstyle ':completion:*:descriptions' format '%F{yellow}Completing %B%d%b%f'$DEFAULT
#zstyle ':completion:*:manuals' separate-sections true
#zstyle ':completion:*:messages' format '%F{YELLOW}%d'$DEFAULT
#zstyle ':completion:*:options' description 'yes'
#zstyle ':completion:*:sudo:*' command-path /usr/local/sbin /usr/local/bin /usr/sbin /usr/bin /sbin /bin
#zstyle ':completion:*:warnings' format '%F{RED}No matches for:''%F{YELLOW} %d'$DEFAULT
#zstyle ':completion::complete:*' use-cache true
