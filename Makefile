all:
	ln -s `pwd`/.zshrc ~/.zshrc
	ln -s `pwd`/.dircolors ~/.dircolors
	ln -s `pwd`/.gitconfig ~/.gitconfig
	ln -s `pwd`/.screenrc ~/.screenrc

.PHONY: cheat
cheat:
	# go get github.com/dufferzafar/cheat
	git clone https://github.com/jahendrie/cheat.git
	ln -s `pwd`/cheat/data ~/.cheatsheets

.PHONY: linux
linux:
	ln -s `pwd`/.zlogin-linux ~/.zlogin
	ln -s `pwd`/.tmux.conf-linux ~/.tmux.conf

.PHONY: osx
osx:
	ln -s `pwd`/.zlogin-osx ~/.zlogin
	ln -s `pwd`/.tmux.conf-osx ~/.tmux.conf
	#defaults write loginwindow AutoLaunchedApplicationDictionary -array-add '{ "Path" = "`pwd`/Environment.app"; "Hide" = 0; }'

.PHONY: bsd
bsd:
	echo "Nothing to do for bsd yet..."

.PHONY: lua-vim
lua-vim:
	ln -s `pwd`/.vimrc ~/.vimrc
	mkdir -p ~/.vim_backup
	mkdir -p ~/.vim/bundle && cd ~/.vim/bundle && git clone https://github.com/Shougo/neobundle.vim.git
	ruby ~/.vim/bundle/rsense/etc/config.rb > ~/.rsense
	
.PHONY: tiny-vim
tiny-vim:
	ln -s `pwd`/.vimrc-tiny ~/.vimrc
	mkdir -p ~/.vim_backup
	mkdir -p ~/.vim/bundle && cd ~/.vim/bundle && git clone https://github.com/Shougo/neobundle.vim.git

.PHONY: clean
clean:
	unlink ~/.zshrc
	unlink ~/.vimrc
	unlink ~/.zlogin
	unlink ~/.tmux.conf
	unlink ~/.dircolors
	rm -fr ~/.vim ~/.vim_backup

