all:
	ln -s `pwd`/.zshrc ~/.zshrc
	ln -s `pwd`/.dircolors ~/.dircolors
	ln -s `pwd`/.gitconfig ~/.gitconfig
	mkdir -p ~/.vim_backup
	mkdir -p ~/.vim/bundle && cd ~/.vim/bundle && git clone https://github.com/Shougo/neobundle.vim.git

.PHONY: linux
linux:
	ln -s `pwd`/.zlogin-linux ~/.zlogin
	ln -s `pwd`/.tmux.conf-linux ~/.tmux.conf

.PHONY: osx
osx:
	ln -s `pwd`/.zlogin-osx ~/.zlogin
	ln -s `pwd`/.tmux.conf-osx ~/.tmux.conf

.PHONY: lua-vim
lua-vim:
	ln -s `pwd`/.vimrc ~/.vimrc
	ruby ~/.vim/bundle/rsense/etc/config.rb > ~/.rsense
	
.PHONY: tiny-vim
tiny-vim:
	ln -s `pwd`/.vimrc-tiny ~/.vimrc

.PHONY: clean
clean:
	unlink ~/.zshrc
	unlink ~/.vimrc
	unlink ~/.zlogin
	unlink ~/.tmux.conf
	unlink ~/.dircolors
	rm -fr ~/.vim ~/.vim_backup

