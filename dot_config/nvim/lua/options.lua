--
-- Options
-- :vim.opt.y for options
--
-- if has('multi_byte_ime')
--    set iminsert=0 imsearch=0
-- endif
local options = {
    autoindent = true,
    -- background = 'dark',
    -- backspace = { 'start', 'eol', 'indent' },
    -- backup = false,
    breakindent = true,
    cmdheight = 1,
    completeopt = { 'menuone', 'noselect' },
    -- highlight the screen line
    cursorline = true,
    -- string-encoding used internally and for RPC communication
    encoding = 'utf-8',
    -- use spaces to inseart a <Tab> -- C-V<Tab> to insert a real tab
    expandtab = true,
    foldenable = true,
    foldlevel = 100,
    foldmethod = 'marker',
    guifont = 'Ricty-Regular-nerd-Powerline 11',
    -- laststatus = 2,
    hlsearch = true,
    inccommand = 'split',
    -- case insensitive searching UNLESS /C or capital in search,
    --ignorecase = true,
    laststatus = 2,
    -- precede each line with its line number
    number = true,
    -- numberwidth = 4,
    pumblend = 5,
    -- pumheight = 10,
    -- relativenumber = false,
    -- scrolloff = 8,
    -- shell = 'fish',
    -- number of spaces to use for each step of indent
    shiftwidth = 4,
    showcmd = true,
    -- showmode = false,
    -- showtabline = 2,
    -- sidescrolloff = 8,
    -- signcolumn = 'yes',
    -- smartcase = true,
    smarttab = true,
    smartindent = true,
    -- splitbelow = false,
    -- splitright = false,
    -- swapfile = false,
    -- number of spaces that a <Tab> counts for
    tabstop = 4,
    -- enable 24-bit RGB color
    termguicolors = true,
    timeoutlen = 300,
    -- set title of the window to 'titlestring'
    title = true,
    undofile = true,
    wildoptions = 'pum',
    winblend = 0
    -- wrap = false -- No Wrap lines,
}

-- vim.opt.backupskip:append({ '/tmp/*', '/private/tmp/*' })
-- encodings to consider
vim.opt.fileencodings:append({
    'utf-8', 'ucs-bom', 'iso-2022-jp-3', 'iso-2022-jp', 'eucjp-ms',
    'euc-jisx0213', 'euc-jp', 'sjis', 'cp932'
})
-- finding files - search down into subfolders,
vim.opt.path:append({ '**' })
vim.opt.shortmess:append('c')
vim.opt.wildignore:append({ '*/node_modules/*' })

for k, v in pairs(options) do vim.opt[k] = v end

-- highlight yanked text for 1 second using the "Visual" highlight group
local augroup_hy = vim.api.nvim_create_augroup("HighlightYank", { clear = true })
vim.api.nvim_create_autocmd("TextYankPost", {
    group = augroup_hy,
    callback = function()
        vim.highlight.on_yank({ higroup = "Visual", timeout = 1000 })
    end
})
