" Plugins {{{1
" NeoBundle
"---------------------------------------------
if has('vim_starting')
    set nocompatible
    set runtimepath+=~/.vim/bundle/neobundle.vim
endif

" Install and configure vim plugins
call neobundle#begin(expand('~/.vim/bundle'))

" Manage neobundle itself
NeoBundleFetch 'Shougo/neobundle.vim'

" Unite.vim {{{2
"---------------------------------------------
NeoBundle 'Shougo/unite.vim'
NeoBundle 'Shougo/neomru.vim'

" List buffers
nnoremap <silent> fb :<C-u>Unite buffer<CR>
" List file_mru as buffer
nnoremap <silent> fu :<C-u>Unite file_mru buffer<CR>
" List files
nnoremap <silent> ff :<C-u>UniteWithBufferDir -buffer-name=dotfiles file<CR>
" List recent files
nnoremap <silent> fm :<C-u>Unite file_mru<CR>
" List registers
nnoremap <silent> fr :<C-u>Unite -buffer-name=register register<CR>
" List and set a yank
let g:unite_source_history_yank_enable = 1
nnoremap <silent> fy :<C-u>Unite history/yank<CR>

" vim-quickrun {{{2
"---------------------------------------------
NeoBundle 'thinca/vim-quickrun'
let g:quickrun_no_default_key_mappings = 1
nnoremap <silent> <C-q> :QuickRun<CR>

"}}}
" Neocomplete.vim {{{2
"---------------------------------------------
NeoBundle 'Shougo/neocomplete.vim'

" Disable AutoComplPop.
let g:acp_enableAtStartup = 0
" Use neocomplete.
let g:neocomplete#enable_at_startup = 1
" Use smartcase.
let g:neocomplete#enable_smart_case = 1
" Set minimum syntax keyword length.
let g:neocomplete#lock_buffer_name_pattern = '\*ku\*'
let g:neocomplete#sources#syntax#min_keyword_length = 4
let g:neocomplete#auto_completion_start_length = 4
" Skip when stuck
let g:neocomplete#skip_auto_completion_time = '0.2'


" Define dictionary.
let g:neocomplete#sources#dictionary#dictionaries = {
    \ 'default' : '',
    \ 'vimshell' : $HOME.'/.vimshell_hist',
    \ 'scheme' : $HOME.'/.gosh_completions'
    \ }

" Define keyword.
if !exists('g:neocomplete#keyword_patterns')
    let g:neocomplete#keyword_patterns = {}
endif
let g:neocomplete#keyword_patterns['default'] = '\h\w*'

" Plugin key-mappings.
inoremap <expr><C-g>     neocomplete#undo_completion()
inoremap <expr><C-l>     neocomplete#complete_common_string()

" Recommended key-mappings.
" <CR>: close popup and save indent.
inoremap <silent> <CR> <C-r>=<SID>my_cr_function()<CR>
function! s:my_cr_function()
  return neocomplete#close_popup() . "\<CR>"
  " For no inserting <CR> key.
  "return pumvisible() ? neocomplete#close_popup() : "\<CR>"
endfunction
" <TAB>: completion.
inoremap <expr><TAB>  pumvisible() ? "\<C-n>" : "\<TAB>"
" <C-h>, <BS>: close popup and delete backword char.
inoremap <expr><C-h> neocomplete#smart_close_popup()."\<C-h>"
inoremap <expr><BS> neocomplete#smart_close_popup()."\<C-h>"
inoremap <expr><C-y>  neocomplete#close_popup()
inoremap <expr><C-e>  neocomplete#cancel_popup()

" Enable omni completion.
autocmd FileType html,markdown setlocal omnifunc=htmlcomplete#CompleteTags
autocmd FileType javascript setlocal omnifunc=javascriptcomplete#CompleteJS
autocmd FileType xml setlocal omnifunc=xmlcomplete#CompleteTags

"}}}
" rsense {{{2
"---------------------------------------------
"NeoBundleLazy 'marcus/rsense', {
"    \ 'autoload': {
"    \   'filetypes': 'ruby'
"    \ },
"    \ }
"NeoBundleLazy 'supermomonga/neocomplete-rsense.vim', {
"    \ 'depends': ['Shougo/neocomplete.vim', 'marcus/rsense'],
"    \ }
"
"let g:rsenseUseOmniFunc = 1
"if !exists('g:neocomplete#force_omni_input_patterns')
"    let g:neocomplete#force_omni_input_patterns = {}
"endif
"let g:neocomplete#force_omni_input_patterns.ruby = '[^. *\t]\.\w*\|\h\w*::'']'

"}}}
" jedi-vim {{{2
"---------------------------------------------
NeoBundle 'davidhalter/jedi-vim'
autocmd FileType python setlocal completeopt-=preview
autocmd FileType python setlocal omnifunc=jedi#completions
let g:jedi#completions_enabled = 0
let g:jedi#auto_vim_configuration = 0
if !exists('g:neocomplete#force_omni_input_patterns')
        let g:neocomplete#force_omni_input_patterns = {}
endif
let g:neocomplete#force_omni_input_patterns.python = '\%([^. \t]\.\|^\s*@\|^\s*from\s.\+import \|^\s*from \|^\s*import \)\w*''])'

"}}}
" emmet-vim {{{2
"---------------------------------------------
NeoBundle 'mattn/emmet-vim'

"}}}
" vim-css3-syntax {{{2
"---------------------------------------------
NeoBundle 'hail2u/vim-css3-syntax'

augroup VimCSS3Syntax
  autocmd!
  autocmd FileType css setlocal iskeyword+=-
augroup END

"}}}
" vim-go {{{2
"---------------------------------------------
NeoBundle 'fatih/vim-go'

":GoInstallBinaries
exe "set rtp+=".globpath($GOPATH, "src/github.com/nsf/gocode/vim")
set completeopt=menu,preview
au FileType go nmap <Leader>i <Plug>(go-info)
au FileType go nmap <Leader>gd <Plug>(go-doc)
au FileType go nmap <Leader>gv <Plug>(go-doc-vertical)
au FileType go nmap <Leader>gb <Plug>(go-doc-browser)
au FileType go nmap <leader>r <Plug>(go-run)
au FileType go nmap <leader>b <Plug>(go-build)
au FileType go nmap <leader>t <Plug>(go-test)

"}}}
" vim-yaml {{{2
"---------------------------------------------
NeoBundle 'stephpy/vim-yaml'

"}}}
" vim-dispatch {{{2
"---------------------------------------------
NeoBundle 'tpope/vim-dispatch'

"}}}
" lightline.vim {{{2
"---------------------------------------------
NeoBundle 'itchyny/lightline.vim'

if !has('gui_running')
  set t_Co=256
endif

let g:lightline = {
      \ 'colorscheme': 'solarized',
      \ 'mode_map': { 'c': 'NORMAL' },
      \ 'active': {
      \   'left': [ [ 'mode', 'paste' ], [ 'fugitive', 'filename' ] ]
      \ },
      \ 'component_function': {
      \   'modified': 'MyModified',
      \   'readonly': 'MyReadonly',
      \   'fugitive': 'MyFugitive',
      \   'filename': 'MyFilename',
      \   'fileformat': 'MyFileformat',
      \   'filetype': 'MyFiletype',
      \   'fileencoding': 'MyFileencoding',
      \   'mode': 'MyMode',
      \ }
      \ }

function! MyModified()
  return &ft =~ 'help\|vimfiler\|gundo' ? '' : &modified ? '+' : &modifiable ? '' : '-'
endfunction

function! MyReadonly()
  return &ft !~? 'help\|vimfiler\|gundo' && &readonly ? '' : ''
endfunction

function! MyFilename()
  return ('' != MyReadonly() ? MyReadonly() . ' ' : '') .
        \ (&ft == 'vimfiler' ? vimfiler#get_status_string() : 
        \  &ft == 'unite' ? unite#get_status_string() : 
        \  &ft == 'vimshell' ? vimshell#get_status_string() :
        \ '' != expand('%:t') ? expand('%:t') : '[No Name]') .
        \ ('' != MyModified() ? ' ' . MyModified() : '')
endfunction

function! MyFugitive()
  if &ft !~? 'vimfiler\|gundo' && exists("*fugitive#head")
    let _ = fugitive#head()
    return strlen(_) ? ''._ : ''
  endif
  return ''
endfunction

function! MyFileformat()
  return winwidth(0) > 70 ? &fileformat : ''
endfunction

function! MyFiletype()
  return winwidth(0) > 70 ? (strlen(&filetype) ? &filetype : 'no ft') : ''
endfunction

function! MyFileencoding()
  return winwidth(0) > 70 ? (strlen(&fenc) ? &fenc : &enc) : ''
endfunction

function! MyMode()
  return winwidth(0) > 60 ? lightline#mode() : ''
endfunction

"}}}

call neobundle#end()

" Use indentations from plugins
filetype plugin indent on

" Check if the plugin for the language is installed
NeoBundleCheck

if !has('vim_starting')
    " #When .vimrc reloaded
    call neobundle#call_hook('on_source')
endif

"}}}
" Indentation {{{1
"---------------------------------------------
au BufNewFile,BufRead *.conf set tabstop=2 shiftwidth=2
au BufNewFile,BufRead *.md set tabstop=2 shiftwidth=2
au BufNewFile,BufRead *.rb set tabstop=2 shiftwidth=2
au BufNewFile,BufRead *.xml set tabstop=2 shiftwidth=2

"}}}
" File encoding configuration {{{1
"---------------------------------------------
if &encoding !=# 'utf-8'
	set encoding=japan
	set fileencoding=japan
endif

if has('iconv')
	let s:enc_enc = 'ecu-jp'
	let s:enc_jis = 'iso-2022-jp'

    " Check if iconv is compatible with eucJP-ms
	if iconv("\x87\x64\x87\x6a", 'cp932', 'eucjp-ms') ==# "\xad\xc5\xad\xcb"
		let s:enc_euc = 'eucjp-ms'
		let s:enc_jis = 'iso-2022-jp-3'
    " Check if iconv is compatible with euc-jisx0213
	elseif iconv("\x87\x64\x87\x6a", 'cp932', 'euc-jisx0213') ==# "\xad\xc5\xad\xcb"
		let s:enc_euc = 'euc-jisx0213'
		let s:enc_jis = 'iso-2022-jp-3'
	endif

    " Set fileencoding
	if &encoding ==# 'utf-8'
		let s:fileencodings_default = &fileencodings
		let &fileencodings = 'utf-8,'. s:enc_jis .','. s:enc_euc .',cp932'
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

" If no Japanese included in the file use encoding
if has('autocmd')
	function! AU_ReCheck_FENC()
		if &fileencoding =~# 'iso-2022-jp' && search("[^\x01-\x7e]", 'n') == 0
			let &fileencoding=&encoding
		endif
	endfunction
endif

" Auto recognize newline codes
set fileformats=unix,dos,mac

" Print multi-byte characters in a proper width
if exists('ambiwidth')
	set ambiwidth=double
endif

"}}}
" Key remappings {{{1
"---------------------------------------------
nnoremap Y y$
nnoremap + <C-a>
nnoremap - <C-x>
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

"}}}
" Options {{{1
"---------------------------------------------
set autoindent
set autoread
set backspace=indent,eol,start
set backup
set backupdir=$HOME/.vim_backup
set cursorline
set directory=$HOME/.vim_backup
set display=lastline
set equalalways
set expandtab
set hidden
set hlsearch
set ignorecase
set laststatus=2
set matchtime=1
set modeline
set number
set pumheight=10
set scrolloff=10
set shiftwidth=4
set showcmd
set showmatch
set smarttab
set smartcase
set softtabstop=4
"set statusline=%<%f%=%h%w%y%{'['.(&fenc!=''?&fenc:&enc).']['.&ff.']'}%9(\ %m%r\ %)[%4v][%12(\ %5l/%5L%)]
set tabstop=4
set tags=
set title
set undolevels=200
set wrap
set writebackup

" Syntax highlight
syntax on

"}}}
" augroup and autocmd {{{1
"---------------------------------------------
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

augroup swapchoice-readonly
  autocmd!
  autocmd SwapExists * let v:swapchoice = 'o'
augroup END

"}}}

" Folding settings
"---------------------------------------------
hi Folded ctermbg=232
" vim: foldmethod=marker
" vim: foldcolumn=3
" vim: foldlevel=0

