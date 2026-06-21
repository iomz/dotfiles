#!/usr/bin/env zsh
#
# Completion
#

[[ -o interactive && -t 0 ]] || return


# Completion paths {{{
# Homebrew-managed completions should be discovered through fpath, not Zinit snippets.
if command -v brew >/dev/null 2>&1; then
    fpath=(
        "$(brew --prefix)/share/zsh/site-functions"
        "$(brew --prefix)/share/zsh-completions"
        $fpath
    )
fi

# Zinit-managed completions.
if [[ -n "${XDG_DATA_HOME}" ]]; then
    fpath=(
        "${XDG_DATA_HOME}/zinit/completions"
        $fpath
    )
fi
# }}}


# compinit {{{
autoload -Uz compinit

if [[ -n "${ZSH_TRUST_INSECURE_COMPLETIONS}" ]]; then
    compinit -C -i
else
    compinit -C
fi
# }}}


# Completion colors {{{
zstyle ':completion:*:default' list-colors ${(s.:.)IOMZ_COLORS}
zstyle ':completion:*:corrections' format $MAGENTA' -- %d (errors: %e) -- '$DEFAULT
zstyle ':completion:*:descriptions' format ' -- '$YELLOW'Completing %B%d%b -- '$DEFAULT
zstyle ':completion:*:commands' list-colors '=*=1;31'
zstyle ':completion:*:builtins' list-colors '=*=1;38;5;142'
zstyle ':completion:*:messages' format $PURPLE' -- %d -- '$DEFAULT
zstyle ':completion:*:options' list-colors '=*=32'
zstyle ':completion:*:options' list-colors '=^(-- *)=34'
zstyle ':completion:*:parameters' list-colors '=*=32'
zstyle ':completion:*:warnings' format ${BROWN_RED}'No matches for: '$RED'%d'$DEFAULT
zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#) ([0-9a-z-]#)*=01;36=0=01'
# }}}


# Completion behavior {{{
zstyle ':completion:*' group-name ''
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'
zstyle ':completion:*' squeeze-slashes true
zstyle ':completion:*' verbose yes

zstyle ':completion:*:approximate:*' max-errors 1 numeric
zstyle ':completion:*:complete:*' cache-path "${ZDOTDIR:-$HOME}/.zcompcache"
zstyle ':completion:*:complete:*' use-cache true
zstyle ':completion:*:default' menu select=2
zstyle ':completion:*:default' list-prompt '%S%M matches%s'
zstyle ':completion:*:functions' ignored-patterns '(_*|pre(cmd|exec))'
zstyle ':completion:*:manuals' separate-sections true
zstyle ':completion:*:manuals.(^1*)' insert-sections true
zstyle ':completion:*:match:*' original only
zstyle ':completion:*:matches' group 'yes'
zstyle ':completion:*:options' auto-description '%d'
zstyle ':completion:*:options' description 'yes'
zstyle ':completion:*:rm:*' file-patterns '*:all-files'
zstyle ':completion:*:sudo:*' command-path /usr/local/sbin /usr/local/bin /usr/sbin /usr/bin /sbin /bin
zstyle ':completion::*:(-command-|export):*' fake-parameters ${${${_comps[(I)-value-*]#*,}%%,*}:#-*-}
zstyle ':completion:*:-tilde-:*' group-order 'named-directories' 'path-directories' 'users' 'expand'
zstyle ':completion:*:*:cd:*' tag-order local-directories directory-stack path-directories
zstyle ':completion:*:*:cd:*:directory-stack' menu yes select
zstyle ':completion:*:*:kill:*' force-list always
zstyle ':completion:*:*:kill:*' insert-ids single
zstyle ':completion:*:*:kill:*' menu yes select
zstyle ':completion:*:*:-command-:*:*' group-order functions builtins commands
zstyle ':completion:*:*:-subscript-:*' tag-order indexes parameters
zstyle ':completion:*:*:*:*:processes' command 'ps -u $LOGNAME -o pid,user,command -w'
zstyle ':completion:*:*:*:*:*' ignore-line 'yes'
zstyle ':completion:*:*:*:*:*' menu select
# }}}


# SSH/scp/rsync {{{
zstyle ':completion:*:ssh:*' group-order hosts-host hosts-ipaddr
zstyle ':completion:*:ssh:*' tag-order 'hosts:-host:host hosts:-ipaddr:ip\ address *'
zstyle ':completion:*:(scp|rsync):*' group-order files all-files hosts-host hosts-ipaddr
zstyle ':completion:*:(scp|rsync):*' tag-order 'hosts:-host:host hosts:-ipaddr:ip\ address *'
zstyle ':completion:*:(ssh|scp|rsync):*:hosts-domain' ignored-patterns '<->.<->.<->.<->' '^[-[:alnum:]]##(.[-[:alnum:]]##)##' '*@*'
zstyle ':completion:*:(ssh|scp|rsync):*:hosts-host' ignored-patterns '*(.|:)*' loopback ip6-loopback localhost ip6-localhost broadcasthost
zstyle ':completion:*:(ssh|scp|rsync):*:hosts-ipaddr' ignored-patterns '^(<->.<->.<->.<->|(|::)([[:xdigit:].]##:(#c,2))##(|%*))' '127.0.0.<->' '255.255.255.255' '::1' 'fe80::*'

zstyle -e ':completion:*:hosts' hosts 'reply=(${=${${${${(@M)${(f)"$(cat ~/.ssh/config 2>/dev/null)"}:#Host *}#Host }:#*\**}:#*\?*}})'
# }}}


# Users {{{
zstyle ':completion:*:*:*:users' ignored-patterns \
    adm amanda apache avahi beaglidx bin cacti canna clamav daemon \
    dbus distcache dovecot fax ftp games gdm gkrellmd gopher \
    hacluster haldaemon halt hsqldb ident junkbust ldap lp mail \
    mailman mailnull mldonkey mysql nagios \
    named netdump news nfsnobody nobody nscd ntp nut nx openvpn \
    operator pcap postfix postgres privoxy pulse pvm quagga radvd \
    rpc rpcuser rpm shutdown squid sshd sync uucp vcsa xfs '_*'
# }}}
