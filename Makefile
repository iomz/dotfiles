UNAME_S := $(shell uname -s)
CANDIDATES := $(wildcard .??*) bin
EXCLUSIONS := .DS_Store .git .gitignore .tmux.conf.darwin .tmux.conf.linux .vimrc .vimrc-tiny .zsh
DOTFILES   := $(filter-out $(EXCLUSIONS), $(CANDIDATES))

.DEFAULT_GOAL := init

all:

init: ## Symlink dotfiles
	@$(foreach val, $(DOTFILES), ln -sfnv $(abspath $(val)) $(HOME)/$(val);)

.PHONY: osx
osx: ## for osx to install Environment.app for startup
	#defaults write loginwindow AutoLaunchedApplicationDictionary -array-add '{ "Path" = "`pwd`/Environment.app"; "Hide" = 0; }'
	brew install fontforge
	pip2 install configparser
	# Ricty
	mkdir -p ~/.fonts
	curl -L http://levien.com/type/myfonts/Inconsolata.otf > ~/.fonts/Inconsolata.otf
	tmp=$(mktemp -d)
	mkdir -p "$tmp"
	curl -L "https://ja.osdn.net/frs/redir.php?m=iij&f=%2Fmix-mplus-ipa%2F63545%2Fmigu-1m-20150712.zip" > "$tmp"/migu-1m-20150712.zip
	unzip "$tmp"/migu-1m-20150712.zip -d "$tmp"
	cp "$tmp"/migu-1m-20150712/migu-1m-regular.ttf ~/.fonts
	cp "$tmp"/migu-1m-20150712/migu-1m-bold.ttf ~/.fonts
	curl -L raw.github.com/metalefty/Ricty/master/ricty_generator.sh > "$tmp"/ricty_generator.sh
	chmod +x "$tmp"/ricty_generator.sh
	"$tmp"/ricty_generator.sh ~/.fonts/Inconsolata.otf ~/.fonts/migu-1m-regular.ttf ~/.fonts/migu-1m-bold.ttf
	mv Ricty-Bold.ttf Ricty-Regular.ttf ~/.fonts
	# NERD
	git clone --depth=1 https://github.com/ryanoasis/nerd-fonts.git "$tmp"/nerd-fonts
	fontforge -script "$tmp"/nerd-fonts/font-patcher ~/.fonts/Ricty-Regular.ttf --fontawesome --fontlinux --octicons --pomicons --powerline --powerlineextra --no-progressbars --quiet
	mv Ricty*.ttf Ricty-Regular-nerd.ttf
	# vim-powerline
	git clone --depth=1 https://github.com/Lokaltog/vim-powerline.git "$tmp"/vim-powerline
	fontforge -lang=py -script "$tmp"/vim-powerline/fontpatcher/fontpatcher Ricty-Regular-nerd.ttf
	mv Ricty*.ttf ~/.fonts/
	# flush
	rm -rf "$tmp"
	cp -f ~/.fonts/*.ttf ~/Library/Fonts/
	fc-cache -vf

.PHONY: dot-config
	mkdir -p ~/.config
	ln -sfnv `pwd`/.config/cheat ~/.config/cheat

.PHONY: neovim
neovim:
	mkdir -p ~/.vim/dein/repos/github.com/Shougo/dein.vim
	git clone https://github.com/Shougo/dein.vim.git ~/.vim/dein/repos/github.com/Shougo/dein.vim
	mkdir -p ~/.config
	ln -sfnv ~/.vim ~/.config/nvim
	ln -sfnv `pwd`/.vimrc ~/.config/nvim/init.vim
	mkdir -p ~/.vim_backup

.PHONY: lua-vim
lua-vim: ## setup lua vim with full options
	ln -s `pwd`/.vimrc ~/.vimrc
	mkdir -p ~/.vim_backup
	mkdir -p ~/.vim/colors
	cp vim_colors/*.vim ~/.vim/colors/
	mkdir -p ~/.vim/bundle && cd ~/.vim/bundle && git clone https://github.com/Shougo/neobundle.vim.git
	#ruby ~/.vim/bundle/rsense/etc/config.rb > ~/.rsense

.PHONY: tiny-vim
tiny-vim: ## vim for a tiny env
	ln -s `pwd`/.vimrc-tiny ~/.vimrc
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

