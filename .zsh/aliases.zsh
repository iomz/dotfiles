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
