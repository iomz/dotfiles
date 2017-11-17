# Ansible
export ANSIBLE_HOSTS=/etc/ansible/hosts
export ANSIBLE_SCP_IF_SSH=y

# $HOME/bin
export PATH=$HOME/bin:$PATH

# Golang
export GOPATH=$HOME/go
if [ -f $GOROOT/misc/zsh/go ]; then
    source $GOROOT/misc/zsh/go
fi
export PATH=$GOPATH/bin:$GOROOT/bin:$PATH

# OS specific
case ${OSTYPE} in
    darwin*)
        # Octave PATH
        export FONTCONFIG_PATH=/opt/X11/lib/X11/fontconfig
        # Homebrew
        export HOMEBREW_PREFIX=/usr/local/Cellar
        export PATH=/usr/local/bin:/usr/local/sbin:$PATH
        ## Install applications via brew-cask into /Applications
        export HOMEBREW_CASK_OPTS="--appdir=/Applications"
        # MacTeX
        eval `/usr/libexec/path_helper -s`
        # Python
        #export PYTHONPATH=/usr/local/lib/python2.7/site-packages
	    # rbenv
	    export PATH=~/.rbenv/shims:$PATH
        eval "$(rbenv init -)"
        ;;
    linux*)
        ;;
esac

