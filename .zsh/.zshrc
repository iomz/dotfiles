# Attach tmux on login
if [ ! -z `which tmux` ]; then
  if [ $SHLVL = 1 ]; then
    if [ $(( `ps aux | grep tmux | grep $USER | grep -v grep | wc -l` )) != 0 ]; then
      echo -n 'Attach tmux session? [Y/n]'
      read YN
      [[ $YN = '' ]] && YN=y
      [[ $YN = y ]] && tmux attach
    fi
  fi
fi

# source .profile and .login
[[ -s ~/.profile ]] && source "$HOME/.profile"
[[ -s ~/.login ]] && source "$HOME/.login"

# avoid duplicates in PATHs
typeset -U path cdpath fpath manpath

# command halfway
autoload history-search-end
zle -N history-beginning-search-backward-end history-search-end
zle -N history-beginning-search-forward-end history-search-end

# completion
autoload -U compinit && compinit
zmodload zsh/complist
zmodload zsh/computil
zstyle ':completion:*' completer _expand _complete _match _prefix _approximate _list _history
zstyle ':completion:*' group-name ''
zstyle ':completion:*' list-colors 'di=36' 'ln=35'
zstyle ':completion:*' list-separator '-->'
zstyle ':completion:*' matcher-list '' 'm:{a-z}={A-Z}' '+m:{A-Z}={a-z}'
zstyle ':completion:*' verbose yes
zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([%0-9]#)*=0=01;31'
zstyle ':completion:*:default' menu select=1
zstyle ':completion:*:descriptions' format '%F{YELLOW}completing %B%d%b'$DEFAULT
zstyle ':completion:*:descriptions' format '%F{yellow}Completing %B%d%b%f'$DEFAULT
zstyle ':completion:*:manuals' separate-sections true
zstyle ':completion:*:messages' format '%F{YELLOW}%d'$DEFAULT
zstyle ':completion:*:options' description 'yes'
zstyle ':completion:*:sudo:*' command-path /usr/local/sbin /usr/local/bin /usr/sbin /usr/bin /sbin /bin /usr/X11R6/bin
zstyle ':completion:*:warnings' format '%F{RED}No matches for:''%F{YELLOW} %d'$DEFAULT
zstyle ':completion::complete:*' use-cache true

bindkey -e
# View matchings by groups
bindkey -M menuselect 'h' vi-backward-char
bindkey -M menuselect 'j' vi-down-line-or-history
bindkey -M menuselect 'k' vi-up-line-or-history
bindkey -M menuselect 'l' vi-forward-char
bindkey "^P" history-beginning-search-backward-end
bindkey "^N" history-beginning-search-forward-end

## Ignore too many list
LISTMAX=100
# History handling
HISTFILE=~/.zsh_history
HISTSIZE=1000000
SAVEHIST=1000000
HISTTIMEFORMAT="[%Y/%M/%D %H:%M:%S] "

# Display process taken longer than 3 seconds
REPORTTIME=3

# <C-q> and <C-s> in Vim with iTerm2
stty start undef
stty stop undef

# default configuration
if [ -f ${ZDOTDIR}/default.zsh ]; then
    source ${ZDOTDIR}/default.zsh
fi

# environmental variables for development
if [ -f ${ZDOTDIR}/devenv.zsh ]; then
    source ${ZDOTDIR}/devenv.zsh
fi

# alias
if [ -f ${ZDOTDIR}/aliases.zsh ]; then
    source ${ZDOTDIR}/aliases.zsh
fi

# setopt
if [ -f ${ZDOTDIR}/setopts.zsh ]; then
    source ${ZDOTDIR}/setopts.zsh
fi

# fzf
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# antigen
if [ -f ${ZDOTDIR}/antigen.zsh ]; then
    source ${ZDOTDIR}/antigen.zsh
    # Syntax highlighting bundle.
    antigen bundle zsh-users/zsh-syntax-highlighting

    # emoji lookup
    antigen bundle b4b4r07/emoji-cli
    # One-liner lookup
    antigen bundle b4b4r07/easy-oneliner

    # Tell Antigen that you're done.
    antigen apply
fi

