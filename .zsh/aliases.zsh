# OS specific zshrc
case ${OSTYPE} in
    darwin*)
        alias ls='ls -CFG'
        alias diff='colordiff'
        alias kess='less -R'
        alias cat='ccat'
        alias vi='nvim'
        alias vim='nvim'
        ;;
    linux*)
        alias ls='ls --color=always'
        ;;
esac
