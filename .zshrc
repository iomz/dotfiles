# start zprof
#zmodload zsh/zprof

export DOTFILES="$HOME/dotfiles"

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
#exec 2> >(color_stderr)
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
#colored_host=$colors[$((`echo "$host_name" | sum | cut -f1 -d' '`%${#colors}))+1]$host_name
colored_host=%{$fg[blue]%}$host_name
colored_colon=%{$reset_color%}:
colored_path=%{$fg[magenta]%}%~
colored_prompt=%{$reset_color%}%#
PROMPT="${colored_time} ${colored_user}${colored_at}${colored_host}${colored_colon}${colored_path} $colored_prompt "

# Editor
export EDITOR=vim

# Locale
export LC_CTYPE=en_US.UTF-8
export LANG=en_US.UTF-8

# disable r
disable r

# avoid duplicates in PATHs
typeset -U path cdpath fpath manpath

# command halfway
autoload history-search-end
zle -N history-beginning-search-backward-end history-search-end
zle -N history-beginning-search-forward-end history-search-end

# OS specific zshrc
case ${OSTYPE} in
    darwin*)
        alias ls='ls -CFG'
        alias diff='colordiff'
        alias kess='less -R'
        alias cat='ccat'
        alias vim='nvim'
        alias gohome='cd ~/go/src/github.com/iomz'
        alias p8='ping 8.8.8.8'
        ;;
    linux*)
        alias ls='ls --color=always'
        ;;
esac

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

# setopts.zsh
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

# fzf
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# antigen
if [ -f ${DOTFILES}/antigen.zsh ]; then
    source ${DOTFILES}/antigen.zsh
    # Syntax highlighting bundle.
    antigen bundle zsh-users/zsh-syntax-highlighting

    # emoji lookup
    #antigen bundle b4b4r07/emoji-cli
    antigen bundle iomz/emoji-cli
    # One-liner lookup
    antigen bundle b4b4r07/easy-oneliner

    # Base16-shell
    antigen bundle chriskempson/base16-shell

    # Tell Antigen that you're done.
    antigen apply
fi

## Base16 Shell
#BASE16_SHELL="$HOME/.config/base16-shell/"
#[ -n "$PS1" ] && \
#    [ -s "$BASE16_SHELL/profile_helper.sh" ] && \
#        eval "$("$BASE16_SHELL/profile_helper.sh")"

# Ansible
export ANSIBLE_SCP_IF_SSH=y

# Editor
export EDITOR=nvim

# $HOME/bin
export PATH=$PATH:$HOME/bin

# XDG_CONFIG_HOME
export XDG_CONFIG_HOME=$HOME/.config

# Fork safety
export OBJC_DISABLE_INITIALIZE_FORK_SAFETY=YES

# OS specific
case ${OSTYPE} in
    darwin*)
        # Go
        export GOPATH=$HOME/go
        export PATH="$PATH:/usr/local/go/bin:$GOPATH/bin"
        # HomeBrew
        export HOMEBREW_PREFIX=/usr/local/Cellar
        export PATH="$PATH:/usr/local/bin:/usr/local/sbin"
        # nodebrew
        export PATH="$PATH:$HOME/.nodebrew/current/bin"
        # arm
        export PATH="$PATH:/opt/gcc-arm-none-eabi-8-2019-q3-update/bin"
        # yarn
        export PATH="$HOME/.yarn/bin:$HOME/.config/yarn/global/node_modules/.bin:$PATH"
        # pyenv
        if command -v pyenv 1>/dev/null 2>&1; then
            eval "$(pyenv init -)"
        fi
        ;;
    linux*)
        ;;
esac

# end zprof
#zprof
