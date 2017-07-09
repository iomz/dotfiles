UNAME_S := $(shell uname -s)
CANDIDATES := $(wildcard .??*) bin
EXCLUSIONS := .DS_Store .git .gitignore .tmux.conf.darwin .tmux.conf.linux .vimrc .vimrc-tiny .zsh
DOTFILES   := $(filter-out $(EXCLUSIONS), $(CANDIDATES))

.DEFAULT_GOAL := init

all:

init:
	@$(foreach val, $(DOTFILES), ln -sfnv $(abspath $(val)) $(HOME)/$(val);)

msc:
	#defaults write loginwindow AutoLaunchedApplicationDictionary -array-add '{ "Path" = "`pwd`/Environment.app"; "Hide" = 0; }'

.PHONY: cheat
cheat:
	# go get github.com/dufferzafar/cheat
	git clone https://github.com/jahendrie/cheat.git
	ln -sf `pwd`/cheat/data ~/.cheatsheets

.PHONY: lua-vim
lua-vim:
	ln -sf `pwd`/.vimrc ~/.vimrc
	mkdir -p ~/.vim_backup
	mkdir -p ~/.vim/colors
	cp vim_colors/*.vim ~/.vim/colors/
	mkdir -p ~/.vim/bundle && cd ~/.vim/bundle && git clone https://github.com/Shougo/neobundle.vim.git
	#ruby ~/.vim/bundle/rsense/etc/config.rb > ~/.rsense

.PHONY: tiny-vim
tiny-vim:
	ln -sf `pwd`/.vimrc-tiny ~/.vimrc
	mkdir -p ~/.vim_backup
	mkdir -p ~/.vim/bundle && cd ~/.vim/bundle && git clone https://github.com/Shougo/neobundle.vim.git

.PHONY: clean
clean:
	unlink ~/.zshenv
	unlink ~/.vimrc
	unlink ~/.screenrc
	unlink ~/.tmux.conf
	unlink ~/.dircolors
	rm -fr ~/.vim ~/.vim_backup

