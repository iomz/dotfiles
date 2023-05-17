--
-- User Commands
--
vim.api.nvim_create_user_command('Upper', 'echo toupper(<q-args>)', {nargs = 1})
-- :command! -nargs=1 Upper echo toupper(<q-args>)
vim.api.nvim_create_user_command('EditInit', "execute(':e $MYVIMRC')", {})
-- :command! EditInit execute(':e $MYVIMRC')
vim.api.nvim_create_user_command('CleanText', "execute(':%s/[^[:print:]]//g')",
                                 {})
-- :command! CleanText execute(':%s/[^[:print:]]//g')
vim.api.nvim_create_user_command('SeparateTag',
                                 [[execute(":%s/]\\(\\S\\)/] \\1/g")]], {})
-- :command! InsertSpace execute(':%s/]\(\S\)/] \1/g')

vim.cmd [[
" let g:colors = getcompletion('', 'color')
let g:colors = [
\'base16-everforest',
\'base16-horizon-terminal-dark',
\'base16-oceanicnext',
\'base16-paraiso',
\'base16-phd',
\'base16-seti',
\'base16-snazzy',
\'base16-solarflare',
\'base16-tokyo-city-dark',
\'base16-tomorrow-night',
\'base16-tomorrow-night-eighties',
\'base16-twilight'
\]

func! NextColors()
    let idx = index(g:colors, g:colors_name)
    let next_color = (idx + 1 >= len(g:colors) ? g:colors[0] : g:colors[idx + 1])
    echo next_color
    return next_color
endfunc
func! PrevColors()
    let idx = index(g:colors, g:colors_name)
    let prev_color = (idx - 1 < 0 ? g:colors[-1] : g:colors[idx - 1])
    echo prev_color
    return prev_color
endfunc
nnoremap cn :exe "colo " .. NextColors()<CR>
nnoremap cp :exe "colo " .. PrevColors()<CR>
]]
