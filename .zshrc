# Avoid duplicates in PATHs
typeset -U path cdpath fpath manpath

# Load ~/.profile normally
[[ -e ~/.profile ]] && source ~/.profile
# Load ~/.profile in sh mode
#[[ -e ~/.profile ]] && emulate sh -c 'source ~/.profile'
# Load .login
[[ -e ~/.login ]] && source ~/.login

# Load tmux on login
#if [ "$TMUX" = "" ]; then tmux attach; fi
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

bindkey -e
export TERM=xterm-256color

# Load completion
fpath=($HOME/.zsh $fpath)
fpath=($HOME/.zsh-completions/src $fpath)
autoload -U compinit && compinit
zmodload zsh/complist
zmodload zsh/computil

# Go completion
if [ -f $GOROOT/misc/zsh/go ]; then
    source $GOROOT/misc/zsh/go
fi

#zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'
zstyle ':completion:*:default' menu select=1
zstyle ':completion::complete:*' use-cache true

# View colorful completions
zstyle ':completion:*' verbose yes
zstyle ':completion:*' completer _expand _complete _match _prefix _approximate _list _history
zstyle ':completion:*:messages' format '%F{YELLOW}%d'$DEFAULT
zstyle ':completion:*:warnings' format '%F{RED}No matches for:''%F{YELLOW} %d'$DEFAULT
zstyle ':completion:*:descriptions' format '%F{YELLOW}completing %B%d%b'$DEFAULT
zstyle ':completion:*:options' description 'yes'
zstyle ':completion:*:descriptions' format '%F{yellow}Completing %B%d%b%f'$DEFAULT

# View matchings by groups
zstyle ':completion:*' group-name ''
bindkey -M menuselect 'h' vi-backward-char
bindkey -M menuselect 'j' vi-down-line-or-history
bindkey -M menuselect 'k' vi-up-line-or-history
bindkey -M menuselect 'l' vi-forward-char
## Colors
autoload -U colors && colors
zstyle ':completion:*' list-colors 'di=36' 'ln=35'
## Kill list
zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([%0-9]#)*=0=01;31'
## sudo list
zstyle ':completion:*:sudo:*' command-path /usr/local/sbin /usr/local/bin /usr/sbin /usr/bin /sbin /bin /usr/X11R6/bin
## Prediction
#autoload -U predict-on && predict-on
## Ignore too many list
LISTMAX=100
## command halfway
autoload history-search-end
zle -N history-beginning-search-backward-end history-search-end
zle -N history-beginning-search-forward-end history-search-end
bindkey "^P" history-beginning-search-backward-end
bindkey "^N" history-beginning-search-forward-end

# setopt
setopt append_history
setopt auto_cd
setopt auto_list
setopt auto_menu
setopt auto_name_dirs
unsetopt auto_remove_slash
setopt auto_pushd
setopt brace_ccl
setopt complete_aliases
setopt complete_in_word
setopt correct
setopt glob_dots
setopt hist_expire_dups_first
setopt hist_ignore_space
setopt hist_reduce_blanks
setopt hist_verify
setopt inc_append_history
setopt list_packed
setopt list_types
setopt noautoremoveslash
setopt no_beep
setopt no_list_beep
setopt no_promptcr
setopt no_tify
setopt numeric_glob_sort
setopt print_eight_bit
setopt share_history

# Setting the style and the color of prompt
#PROMPT=$'%{\e[0;31m%}%* %n$ '
PROMPT="%{$fg[cyan]%}%T %{$fg[red]%}%n%{$fg[green]%}@%{$fg[blue]%}%m %{$fg[magenta]%}%~ %{$reset_color%}%#"
#RPROMPT=$'%{\e[0;33m%}%/%{\e[m%}'
#RPROMPT="%{$fg_bold[yellow]%}%/%{$reset_color%}%"

# History handling
HISTFILE=~/.zsh_history
HISTSIZE=1000000
SAVEHIST=1000000
HISTTIMEFORMAT="[%Y/%M/%D %H:%M:%S] "

# Display process taken longer than 3 seconds
REPORTTIME=3

# Set separators
zstyle ':completion:*' list-separator '-->'
zstyle ':completion:*:manuals' separate-sections true

# <C-q> and <C-s> in Vim with iTerm2
stty start undef
stty stop undef

