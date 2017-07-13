# Ansible
export ANSIBLE_HOSTS=/etc/ansible/hosts
export ANSIBLE_SCP_IF_SSH=y

# $HOME/bin
export PATH=$HOME/bin:$PATH

# Golang
export GOPATH=$HOME/go
export GOROOT=/usr/local/opt/go/libexec
if [ -f $GOROOT/misc/zsh/go ]; then
    source $GOROOT/misc/zsh/go
fi
export PATH=$GOPATH/bin:$GOROOT/bin:$PATH

# RVM
[[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm"

# OS specific
case ${OSTYPE} in
    darwin*)
        # Ansible
        function load_ansible() {
            #source /opt/ansible/hacking/env-setup -q
            source /opt/ansible/hacking/env-setup
        }
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
        export PYTHONPATH=/usr/local/lib/python2.7/site-packages
        ;;
    linux*)
        ;;
esac

