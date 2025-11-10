#!/usr/bin/env zsh
#
# asdf
#

export ASDF_DATA_DIR="${XDG_DATA_HOME}/asdf"
export PATH="${ASDF_DATA_DIR:-$HOME/.asdf}/shims:$PATH"

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
        # golang
        export GOPATH=$HOME/go
        path=( $GOPATH/bin(N-/) $HOME/.ghg/bin(N-/) $path )
        # nodejs
        #brew install gpg gawk
        # python
        #brew install openssl readline sqlite3 xz zlib tcl-tk
        # ruby
        #brew install openssl@3 readline libyaml gmp
        export RUBY_CONFIGURE_OPTS="--with-openssl-dir=$(brew --prefix openssl@3)"
        ;;
    linux*)
        # golang
        export GOPATH=$HOME/go
        path=( $GOPATH/bin(N-/) $HOME/.ghg/bin(N-/) $path )
        # nodejs
        #apt install dirmngr gpg curl gawk
        # python
        #apt install build-essential libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev curl libncursesw5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev
        # ruby
        # apt-get install autoconf patch build-essential rustc libssl-dev libyaml-dev libreadline6-dev zlib1g-dev libgmp-dev libncurses5-dev libffi-dev libgdbm6 libgdbm-dev libdb-dev uuid-dev
        ;;
esac
