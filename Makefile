UNAME_S := $(shell uname -s)
CANDIDATES := $(wildcard .??*) bin
EXCLUSIONS := .DS_Store .git .gitignore .tmux.conf.darwin .tmux.conf.linux .vimrc .vimrc-tiny .zsh
DOTFILES   := $(filter-out $(EXCLUSIONS), $(CANDIDATES))

.DEFAULT_GOAL := init

all:

init: ## Symlink dotfiles
	@$(foreach val, $(DOTFILES), ln -sfnv $(abspath $(val)) $(HOME)/$(val);)

.PHONY: osx
msc: ## for osx to install Environment.app for startup
	#defaults write loginwindow AutoLaunchedApplicationDictionary -array-add '{ "Path" = "`pwd`/Environment.app"; "Hide" = 0; }'

.PHONY: cheat
cheat: ## install cheat command
	# go get github.com/dufferzafar/cheat
	git clone https://github.com/jahendrie/cheat.git
	ln -sf `pwd`/cheat/data ~/.cheatsheets

.PHONY: lua-vim
lua-vim: ## setup lua vim with full options
	ln -sf `pwd`/.vimrc ~/.vimrc
	mkdir -p ~/.vim_backup
	mkdir -p ~/.vim/colors
	cp vim_colors/*.vim ~/.vim/colors/
	mkdir -p ~/.vim/bundle && cd ~/.vim/bundle && git clone https://github.com/Shougo/neobundle.vim.git
	#ruby ~/.vim/bundle/rsense/etc/config.rb > ~/.rsense

.PHONY: tiny-vim
tiny-vim: ## vim for a tiny env
	ln -sf `pwd`/.vimrc-tiny ~/.vimrc
	mkdir -p ~/.vim_backup
	mkdir -p ~/.vim/bundle && cd ~/.vim/bundle && git clone https://github.com/Shougo/neobundle.vim.git

.PHONY: clean
clean: ## Unlink dotfiles
	@-$(foreach val, $(DOTFILES), unlink $(HOME)/$(val);)
	rm -fr ~/.vim ~/.vim_backup

.PHONY: help
help: ## Self-documented Makefile
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
    		| sort \
            | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

