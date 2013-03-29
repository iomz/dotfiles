"Encoding configuration
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

set fileformats=unix,dos,mac

if exists('ambiwidth')
	set ambiwidth=double
endif

" java
let java_heightligt_all = 1
let java_heightligt_functions = "style"
let java_allow_cpp_keywords = 1

imap <C-d> <Del>

"inoremap <C-b> <Left>
"inoremap <C-n> <Down>
"inoremap <C-p> <Up>
"inoremap <C-f> <Right>

"inoremap {} {}<LEFT>
"inoremap [] []<LEFT>
"inoremap () ()<LEFT>
"inoremap "" ""<LEFT>
"inoremap '' ''<LEFT>
"inoremap <> <><LEFT>

augroup InsertHook
autocmd!
autocmd InsertEnter * highlight StatusLine guifg=#ccdc90 guibg=#2E4340
autocmd InsertLeave * highlight StatusLine guifg=#2E4340 guibg=ccdc90
augroup END

autocmd FileType java :setlocal omnifunc=javacomplete#Complete
autocmd FileType java :setlocal completefunc=javacomplete#CompleteParamsInfo

augroup BinaryXXD
	autocmd!
	autocmd BufReadPre  *.bin let &binary =1
	autocmd BufReadPost * if &binary | silent %!xxd -g 1
	autocmd BufReadPost * set ft=xxd | endif
	autocmd BufWritePre * if &binary | %!xxd -r | endif
	autocmd BufWritePost * if &binary | silent %!xxd -g 1
	autocmd BufWritePost * set nomod | endif
augroup END

autocmd FileType html setlocal includeexpr=substitute(v:fname,'^\\/','','') | setlocal path+=;/

au BufNewFile,BufRead *.c set tabstop=8
au BufNewFile,BufRead *.java set tabstop=4
au BufNewFile,BufRead *.py set tabstop=4 expandtab

"set backspace+=start,eol,indent
set tags=./.tags
set sm
set ai
set notitle
set listchars=tab:^\ \,trail:-,extends:>,precedes:<
set showmatch
set number
set shiftwidth=4
set tabstop=4
set softtabstop=4
set expandtab
set smarttab
set hlsearch
set laststatus=2
set showcmd
set statusline=%<%f%=%h%w%y%{'['.(&fenc!=''?&fenc:&enc).']['.&ff.']'}%9(\ %m%r\ %)[%4v][%12(\ %5l/%5L%)]
syntax on
set modeline
set nobackup
set smartcase
set showmatch
set fileencoding=utf-8
set encoding=utf-8
set scrolloff=10
set autoindent
set hidden
set runtimepath+=~/.vim,~/.vim/colors,~/.vim/plugin,~/.vim/autoload
set cursorline

"Start unbundle
runtime bundle/vim-unbundle/unbundle.vim
