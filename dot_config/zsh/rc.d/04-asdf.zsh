#!/usr/bin/env zsh
#
# asdf
#

export ASDF_DATA_DIR="${XDG_DATA_HOME}/asdf"

# Completions and compinit are interactive-shell work only.
[[ -o interactive ]] || return

if [[ ! -d "${ASDF_DATA_DIR:-$HOME/.asdf}/completions" ]]; then
    mkdir -p "${ASDF_DATA_DIR:-$HOME/.asdf}/completions"
    asdf completion zsh > "${ASDF_DATA_DIR:-$HOME/.asdf}/completions/_asdf"
fi

# append completions to fpath
fpath=(${ASDF_DATA_DIR:-$HOME/.asdf}/completions $fpath)
# initialise completions with ZSH's compinit
autoload -Uz compinit && compinit

# install dependencies for plugins
# TODO: this seems wrong
case ${OSTYPE} in
    darwin*)
        export RUBY_CONFIGURE_OPTS="--with-openssl-dir=$(brew --prefix openssl@3)"
        ;;
    linux*)
        ;;
esac
