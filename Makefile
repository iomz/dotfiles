all:
	ln -s `pwd`/.zshrc ~/.zshrc
	ln -s `pwd`/.vimrc ~/.vimrc
	ln -s `pwd`/.login ~/.login
	ln -s `pwd`/.tmux.conf ~/.tmux.conf
	ln -s `pwd`/.dircolors ~/.dircolors
	mkdir -p ~/.vim_backup
	mkdir -p ~/.vim/bundle && cd ~/.vim/bundle && git clone https://github.com/Shougo/neobundle.vim.git

.PHONY: osx
osx:
	ln -s `pwd`/.zlogin ~/.zlogin

.PHONY: clean
clean:
	unlink ~/.zshrc
	unlink ~/.vimrc
	unlink ~/.login
	unlink ~/.tmux.conf
	unlink ~/.dircolors
	rm -fr ~/.vim ~/.vim_backup

