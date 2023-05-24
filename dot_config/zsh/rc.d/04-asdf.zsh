#!/usr/bin/env zsh
#
# asdf
#

export ASDF_DIR=$HOME/.asdf
if [[ ! -d "${ASDF_DIR}" ]]; then
    git clone https://github.com/asdf-vm/asdf.git ${ASDF_DIR} --branch v0.11.3
fi

. "${ASDF_DIR}/asdf.sh"

# append completions to fpath
fpath=(${ASDF_DIR}/completions $fpath)

# install dependencies for plugins
# macOS
#brew install gpg gawk
#brew install openssl readline sqlite3 xz zlib tcl-tk
# Debian
#apt install dirmngr gpg curl gawk
#apt install build-essential libssl-dev zlib1g-dev \
# libbz2-dev libreadline-dev libsqlite3-dev curl \
# libncursesw5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev
