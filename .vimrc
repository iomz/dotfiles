" #Encoding configuration
if &encoding !=# 'utf-8'
	set encoding=japan
	set fileencoding=japan
endif
if has('iconv')
	let s:enc_enc = 'ecu-jp'
	let s:enc_jis = 'iso-2022-jp'
	if iconv("\x87\x64\x87\x6a", 'cp932', 'eucjp-ms') ==# "\xad\xc5\xad\xcb"
		let s:enc_euc = 'eucjp-ms'
		let s:enc_jis = 'iso-2022-jp-3'
	elseif iconv("\x87\x64\x87\x6a", 'cp932', 'euc-jisx0213') ==# "\xad\xc5\xad\xcb"
		let s:enc_euc = 'euc-jisx0213'
		let s:enc_jis = 'iso-2022-jp-3'
	endif
	if &encoding ==# 'utf-8'
		let s:fileencodings_default = &fileencodings
		let &fileencodings = s:enc_jis .','. s:enc_euc .',cp932'
		let &fileencodings = &fileencodings .','. s:fileencodings_default
		unlet s:fileencodings_default
	else
		let &fileencodings = &fileencodings .','. s:enc_jis
		set fileencodings+=utf-8,ucs-2le,ucs-2
		if &encoding =~# '^\(euc-jp\|euc-jisx0213\|eucjp-ms\)$'
			set fileencodings+=cp932
			set fileencodings-=euc-jp
			set fileencodings-=euc-jisx0213
			set fileencodings-=eucjp-ms
			let &encoding = s:enc_euc
			let &fileencoding = s:enc_euc
		else
			let &fileencodings = &fileencodings .','. s:enc_euc
		endif
	endif
	unlet s:enc_euc
	unlet s:enc_jis
endif
if has('autocmd')
	function! AU_ReCheck_FENC()
		if &fileencoding =~# 'iso-2022-jp' && search("[^\x01-\x7e]", 'n') == 0
			let &fileencoding=&encoding
		endif
	endfunction
endif
if exists('ambiwidth')
	set ambiwidth=double
endif
set fileformats=unix,dos,mac

" #Insert mode keymaps
inoremap <C-d> <Del>
inoremap <C-b> <Left>
inoremap <C-n> <Down>
inoremap <C-p> <Up>
inoremap <C-f> <Right>
"inoremap { {}<LEFT>
"inoremap [ []<LEFT>
"inoremap ( ()<LEFT>
"inoremap " ""<LEFT>
"inoremap ' ''<LEFT>
"inoremap < <><LEFT>

" #Indentation
au BufNewFile,BufRead *.css set tabstop=2 shiftwidth=2
au BufNewFile,BufRead *.conf set tabstop=2 shiftwidth=2
au BufNewFile,BufRead *.erb set tabstop=2 shiftwidth=2
au BufNewFile,BufRead *.rb set tabstop=2 shiftwidth=2

" #Options
"set backspace+=start,eol,indent
set antialias
"set autochdir
set autoindent
set autoread
set backup
set backupdir=$HOME/.vim_backup
set cursorline
set directory=$HOME/.vim_backup
set encoding=utf-8
set equalalways
set expandtab
set fileencoding=utf-8
set gdefault
set hidden
set hlsearch
set ignorecase
set laststatus=2
"set list
"set listchars=tab:^\ \,trail:-,extends:>,precedes:<
set modeline
set number
set runtimepath+=~/.vim,~/.vim/plugin,~/.vim/autoload
set scrolloff=10
set shiftwidth=4
set showcmd
set showmatch
set smarttab
set smartcase
set softtabstop=4
set statusline=%<%f%=%h%w%y%{'['.(&fenc!=''?&fenc:&enc).']['.&ff.']'}%9(\ %m%r\ %)[%4v][%12(\ %5l/%5L%)]
set tabstop=4
set title
set undolevels=200
set writebackup

" # Syntax highlight
syntax on

augroup InsertHook
    autocmd!
    autocmd InsertEnter * highlight StatusLine guifg=#ccdc90 guibg=#2E4340
    autocmd InsertLeave * highlight StatusLine guifg=#2E4340 guibg=ccdc90
augroup END

augroup BinaryXXD
	autocmd!
	autocmd BufReadPre  *.bin let &binary =1
	autocmd BufReadPost * if &binary | silent %!xxd -g 1
	autocmd BufReadPost * set ft=xxd | endif
	autocmd BufWritePre * if &binary | %!xxd -r | endif
	autocmd BufWritePost * if &binary | silent %!xxd -g 1
	autocmd BufWritePost * set nomod | endif
augroup END

