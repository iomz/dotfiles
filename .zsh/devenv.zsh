# Ansible
export ANSIBLE_SCP_IF_SSH=y

# $HOME/bin
export PATH=$PATH:$HOME/bin

# XDG_CONFIG_HOME
export XDG_CONFIG_HOME=$HOME/.config

# OS specific
case ${OSTYPE} in
    darwin*)
        # Go
        export GOPATH=$HOME/go
        export PATH=$PATH:/usr/local/go/bin:$GOPATH/bin
        # HomeBrew
        export HOMEBREW_PREFIX=/usr/local/Cellar
        export PATH=$PATH:/usr/local/bin:/usr/local/sbin
        # nodebrew
        export PATH=$PATH:$HOME/.nodebrew/current/bin
        # MagicScript
        source $HOME/MagicLeap/mlsdk/v0.20.0/envsetup.sh
        export MLCERT=$HOME/MagicLeap/mlsdk/certs/iomz-dev.cert
        ## Octave PATH
        #export FONTCONFIG_PATH=/opt/X11/lib/X11/fontconfig
        ## Install applications via brew-cask into /Applications
        export HOMEBREW_CASK_OPTS="--appdir=/Applications"
        ## MacTeX
        #eval `/usr/libexec/path_helper -s`
        ## Python
        #export PYTHONPATH=/usr/local/lib/python2.7/site-packages
        #export PATH="/usr/local/opt/python/libexec/bin:$PATH"
        ## rbenv
        #export PATH=~/.rbenv/shims:$PATH
        #eval "$(rbenv init -)"
        ;;
    linux*)
        ;;
esac

