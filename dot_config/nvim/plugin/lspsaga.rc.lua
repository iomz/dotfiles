local status, lspsaga = pcall(require, "lspsaga")
if (not status) then return end

lspsaga.setup({
    ui = {
        -- This option only works in Neovim 0.9
        title = true,
        -- Border type can be single, double, rounded, solid, shadow.
        border = 'rounded',
        expand = "",
        collapse = "",
        colors = {normal_bg = '#002b36'},
        code_action = "󱧡",
        incoming = " ",
        outgoing = " ",
        hover = ' ',
        kind = {},
        -- winblend = 0,
        winblend = 10
    },
    symbol_in_winbar = { -- symbol
        separator = " > "
    }
})

local opts = {noremap = true, silent = true}
vim.keymap.set('n', '<c-j>', '<cmd>Lspsaga diagnostic_jump_next<CR>', opts)
vim.keymap.set('n', 'K', '<cmd>Lspsaga hover_doc<CR>', opts)
vim.keymap.set('n', 'gl', '<cmd>Lspsaga show_line_diagnostics<CR>', opts)
vim.keymap.set('n', 'gp', '<cmd>Lspsaga peek_definition<CR>', opts)
vim.keymap.set('n', 'gs', '<cmd>Lspsaga lsp_finder<CR>', opts)
vim.keymap.set('n', 'gR', '<cmd>Lspsaga rename<CR>', opts)
vim.keymap.set('i', '<c-K>', '<cmd>Lspsaga signature_help<CR>', opts)
vim.keymap.set({"n", "v"}, "<leader>ca", "<cmd>Lspsaga code_action<CR>")
