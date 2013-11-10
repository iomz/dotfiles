# Load ~/.profile normally
source ~/.profile
# Load ~/.profile in sh mode
#[[ -e ~/.profile ]] && emulate sh -c 'source ~/.profile'

# Load tmux on login
#if [ "$TMUX" = "" ]; then tmux attach; fi

bindkey -e

autoload -U compinit
compinit

setopt list_packed
setopt list_types
setopt auto_cd
setopt auto_pushd
setopt correct
setopt noautoremoveslash
setopt print_eight_bit

zstyle ':completion:*' list-colors 'di=36' 'ln=35'
zstyle ':completion:*:default' menu select=1

#autoload predict-on
#predict-on

autoload -U colors && colors

# Setting the style and the color of prompt
#PROMPT=$'%{\e[0;31m%}%* %n$ '
PROMPT="%{$fg[blue]%}%T %{$fg[red]%}%n%{$reset_color%}@%{$fg[cyan]%}%m %{$fg[magenta]%}%1~ %{$reset_color%}%#"
#RPROMPT=$'%{\e[0;33m%}%/%{\e[m%}'
RPROMPT="%{$fg[yellow]%}%/%{$reset_color%}%"

HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt hist_ignore_dups
setopt share_history
setopt append_history
setopt inc_append_history
setopt hist_no_store
setopt hist_reduce_blanks

# Locale setting
export LC_ALL=en_US.UTF-8
# export LANG="en_US.UTF-8"
# export LANG="ja_JP.UTF-8"
# export LANGUAGE="en_US.UTF-8"

# Display process taken longer than 3 seconds
REPORTTIME=3

# alias
