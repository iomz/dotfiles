local status, mason_lspconfig = pcall(require, "mason-lspconfig")
if (not status) then return end

local augroup_format = vim.api.nvim_create_augroup("Format", {clear = true})
local enable_format_on_save = function(_, bufnr)
    vim.api.nvim_clear_autocmds({group = augroup_format, buffer = bufnr})
    vim.api.nvim_create_autocmd("BufWritePre", {
        group = augroup_format,
        buffer = bufnr,
        callback = function() vim.lsp.buf.format({bufnr = bufnr}) end
    })
end

mason_lspconfig.setup_handlers({
    function(server)
        local opt = {
            -- Function executed when the LSP server startup
            on_attach = function(client, bufnr)
                -- Enable completion
                local function buf_set_option(...)
                    vim.api.nvim_buf_set_option(bufnr, ...)
                end
                buf_set_option('omnifunc', 'v:lua.vim.lsp.omnifunc')

                -- Mappings
                local function buf_set_keymap(...)
                    vim.api.nvim_buf_set_keymap(bufnr, ...)
                end
                local opts = {noremap = true, silent = true}
                buf_set_keymap('n', 'g]',
                               '<cmd>lua vim.diagnostic.goto_next()<CR>', opts)
                buf_set_keymap('n', 'g[',
                               '<cmd>lua vim.diagnostic.goto_prev()<CR>', opts)
                -- See `:help vim.lsp.*` for documentation on any of the below functions
                buf_set_keymap('n', 'gD',
                               '<Cmd>lua vim.lsp.buf.declaration()<CR>', opts)
                buf_set_keymap('n', 'ga',
                               '<cmd>lua vim.lsp.buf.code_action()<CR>', opts)
                buf_set_keymap('n', 'gd',
                               '<cmd>lua vim.lsp.buf.definition()<CR>', opts)
                buf_set_keymap('n', 'ge',
                               '<cmd>lua vim.diagnostic.open_float()<CR>', opts)
                buf_set_keymap('n', 'gf',
                               '<cmd>lua vim.lsp.buf.formatting()<CR>', opts)
                -- buf_set_keymap('n', 'gd', '<Cmd>lua vim.lsp.buf.definition()<CR>', opts)
                buf_set_keymap('n', 'gi',
                               '<cmd>lua vim.lsp.buf.implementation()<CR>', opts)
                buf_set_keymap('n', 'gn', '<cmd>lua vim.lsp.buf.rename()<CR>',
                               opts)
                buf_set_keymap('n', 'gr',
                               '<cmd>lua vim.lsp.buf.references()<CR>', opts)
                buf_set_keymap('n', 'gt',
                               '<cmd>lua vim.lsp.buf.type_definition()<CR>',
                               opts)
                buf_set_keymap('n', 'K', '<cmd>lua vim.lsp.buf.hover()<CR>',
                               opts)

                -- format
                enable_format_on_save(client, bufnr)
            end
        }
        require('lspconfig')[server].setup(opt)
    end
})

mason_lspconfig.setup {automatic_installation = true}

-- local lspconfig = require('lspconfig')
-- mason_lspconfig.setup_handlers({
--  function(server_name)
--    lspconfig[server_name].setup(opts)
--  end,
--  ["lua_ls"] = function ()
--      lspconfig.lua_ls.setup {
--          settings = {
--    Lua = {
--      diagnostics = {
--        -- Get the language server to recognize the `vim` global
--        globals = { 'vim' },
--      },
--
--      workspace = {
--        -- Make the server aware of Neovim runtime files
--        library = vim.api.nvim_get_runtime_file("", true),
--        checkThirdParty = false
--      },
--    },
--          }
--      }
--  end,
-- })
