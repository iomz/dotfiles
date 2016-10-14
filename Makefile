all:
	ln -sf `pwd`/.dircolors ~/.dircolors
	ln -sf `pwd`/.gitconfig ~/.gitconfig
	ln -sf `pwd`/.screenrc ~/.screenrc
	ln -sf `pwd`/.zshrc ~/.zshrc

.PHONY: cheat
cheat:
	# go get github.com/dufferzafar/cheat
	git clone https://github.com/jahendrie/cheat.git
	ln -sf `pwd`/cheat/data ~/.cheatsheets

.PHONY: linux
linux:
	ln -sf `pwd`/.tmux.conf-linux ~/.tmux.conf
	ln -sf `pwd`/.zlogin-linux ~/.zlogin

.PHONY: osx
osx:
	ln -sf `pwd`/.tmux.conf-osx ~/.tmux.conf
	ln -sf `pwd`/.zlogin-osx ~/.zlogin
	#defaults write loginwindow AutoLaunchedApplicationDictionary -array-add '{ "Path" = "`pwd`/Environment.app"; "Hide" = 0; }'

.PHONY: bsd
bsd:
	echo "Nothing to do for bsd yet..."

.PHONY: msc
msc:
	ln -sf `pwd`/.octaverc ~/.octaverc

.PHONY: lua-vim
lua-vim:
	ln -sf `pwd`/.vimrc ~/.vimrc
	mkdir -p ~/.vim_backup
	mkdir -p ~/.vim/bundle && cd ~/.vim/bundle && git clone https://github.com/Shougo/neobundle.vim.git
	#ruby ~/.vim/bundle/rsense/etc/config.rb > ~/.rsense

.PHONY: tiny-vim
tiny-vim:
	ln -sf `pwd`/.vimrc-tiny ~/.vimrc
	mkdir -p ~/.vim_backup
	mkdir -p ~/.vim/bundle && cd ~/.vim/bundle && git clone https://github.com/Shougo/neobundle.vim.git

.PHONY: clean
clean:
	rm -f ~/.zshrc
	rm -f ~/.vimrc
	rm -f ~/.zlogin
	rm -f ~/.screenrc
	rm -f ~/.tmux.conf
	rm -f ~/.dircolors
	rm -fr ~/.vim ~/.vim_backup

