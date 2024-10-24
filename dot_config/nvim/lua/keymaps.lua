-- ====================================================================================
-- KeyMap
-- ':map' is recursive
-- ':noremap' is non-recursive
-- n  Normal mode map. Defined using ':nmap' or ':nnoremap'.
-- i  Insert mode map. Defined using ':imap' or ':inoremap'.
-- v  Visual and select mode map. Defined using ':vmap' or ':vnoremap'.
-- x  Visual mode map. Defined using ':xmap' or ':xnoremap'.
-- s  Select mode map. Defined using ':smap' or ':snoremap'.
-- c  Command-line mode map. Defined using ':cmap' or ':cnoremap'.
-- o  Operator pending mode map. Defined using ':omap' or ':onoremap'.
-- ====================================================================================
-- local keymap = vim.keymap
local keymap = vim.api.nvim_set_keymap

--
-- nmap
--

-- Start interactive EasyAlign for a motion/text object (e.g. gaip)
-- keymap('', 'ga', '<Plug>(EasyAlign)')

--
-- noremap
--

-- move cursor to the beginning of the line (soft)
keymap('', 'H', '^', { noremap = true })
-- move cursor to the end of the line
keymap('', 'L', '$', { noremap = true })
-- keymap('', '<leader>c', 'gg0vG$y', {noremap = true})
-- move cursor to the beginning of the line (hard)
keymap('', '<leader>H', '0', { noremap = true })
-- scroll up
-- keymap('n', '<C-b>', ':call comfortable_motion#flick(-40)<CR>', { noremap=true })
-- scroll down
-- keymap('n', '<C-f>', ':call comfortable_motion#flick(40)<CR>', { noremap=true })

--
-- Normal mode
--

-- unhighlight search result
keymap('n', '<Esc><Esc>', ':<C-u>nohlsearch<CR>', { noremap = true })
-- reload config
-- keymap('n', '<leader><Leader>', '<cmd>lua ReloadConfig()<CR>', {noremap = true})
-- keymap('n', '<leader><Leader>', ':source $MYVIMRC<CR>', {noremap = true})
-- move window
-- keymap('n', '<leader><Tab>', '<C-w>w', { noremap=true })
-- buffer
keymap('n', '<leader>bp', ':bprevious<CR>', { noremap = true })
keymap('n', '<leader>bn', ':bnext<CR>', { noremap = true })
keymap('n', '<leader>bd', ':bdelete<CR>', { noremap = true })
--keymap('n', '<leader>gn', ':lnext<CR>', { noremap = true })
--keymap('n', '<leader>gp', ':lprevious<CR>', { noremap = true })
keymap('n', '<leader>nt', '<cmd>lua require("neotest").run.run()<CR>', { noremap = true })
keymap('n', '<leader>S', '<cmd>lua require("spectre").toggle()<CR>', { noremap = true })
-- open tig with current file
keymap('n', '<leader>T', ':TigOpenCurrentFile<CR>', { noremap = true })
-- open tig with Project root path
keymap('n', '<leader>tt', ':TigOpenProjectRootDir<CR>', { noremap = true })
-- open tig grep
keymap('n', '<leader>tg', ':TigGrep<CR>', { noremap = true })
-- resume from last grep
keymap('n', '<leader>tr', ':TigGrepResume<CR>', { noremap = true })
-- open tig grep with the word under the cursor
keymap('n', '<leader>tc', ':<C-u>:TigGrep<Space><C-R><C-W><CR>', { noremap = true })
-- open tig blame with current file
keymap('n', '<leader>tb', ':TigBlame<CR>', { noremap = true })
-- select all
keymap('n', '<C-a>', 'gg0vG$', { noremap = true })
-- tagbar
keymap('n', '<C-l>', ':Tagbar<CR>', { noremap = true })
-- minimap
--keymap('n', '<C-m>', ':MinimapToggle<CR>', { noremap = true })
-- quickrun
keymap('n', '<C-q>', ':Jaq<CR>', { noremap = true })
-- reload init.lua
-- keymap('n', '<C-s>', ':so $MYVIMRC<CR>', { noremap=true })
keymap('n', '<C-t>', ':NERDTreeToggle<CR>', { noremap = true })
-- yankring
-- keymap('n', '<C-y>', ':YRShow<CR>', {noremap = true})
keymap('n', 'Y', 'y$', { noremap = true })
keymap('n', '+', '<C-a>', { noremap = true })
keymap('n', '-', '<C-x>', { noremap = true })

--
-- Insert mode
--

-- inoremap <silent><expr> <TAB>
--      \ pumvisible() ? '\<C-n>' :
--      \ <SID>check_back_space() ? '\<TAB>' :
--      \ coc#refresh()
-- keymap('i', '<expr><TAB>', "pumvisible() ? '<C-n>' : '<TAB>'", {noremap = true})
-- keymap('i', '<expr><S-TAB>', "pumvisible() ? '<C-p>' : '<C-h>'",
--       {noremap = true})

-- Visual and Select mode
keymap('v', '<Enter>', ':EasyAlign<CR>', { noremap = true })

--
-- Visual mode
-- xmap
--

-- Start interactive EasyAlign in visual mode (e.g. vipga)
-- keymap('x', 'ga', '<Plug>(EasyAlign)')

--
-- Select mode
-- smap
--

--
-- Terminal mode
-- keymap('t', '<ESC>', '<C-\\><C-n>', { noremap=true, silent=true })
