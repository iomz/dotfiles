-- vim.lsp.set_log_level("debug")
-- IMPORTANT: make sure to setup neodev BEFORE lspconfig
-- require("neodev").setup()
local status, lspconfig = pcall(require, "lspconfig")
if (not status) then return end
local util = require('lspconfig/util')

local protocol = require('vim.lsp.protocol')
protocol.CompletionItemKind = {
    '', -- Text
    '', -- Method
    '', -- Function
    '', -- Constructor
    '', -- Field
    '', -- Variable
    '', -- Class
    'ﰮ', -- Interface
    '', -- Module
    '', -- Property
    '', -- Unit
    '', -- Value
    '', -- Enum
    '', -- Keyword
    '﬌', -- Snippet
    '', -- Color
    '', -- File
    '', -- Reference
    '', -- Folder
    '', -- EnumMember
    '', -- Constant
    '', -- Struct
    '', -- Event
    'ﬦ', -- Operator
    '' -- TypeParameter
}

-- LSP handlers
vim.lsp.handlers["textDocument/publishDiagnostics"] =
    vim.lsp.with(vim.lsp.diagnostic.on_publish_diagnostics,
                 {virtual_text = false})

-- Diagnostic publication
vim.lsp.handlers["textDocument/publishDiagnostics"] =
    vim.lsp.with(vim.lsp.diagnostic.on_publish_diagnostics, {
        underline = true,
        update_in_insert = false,
        virtual_text = {spacing = 4, prefix = "●"},
        severity_sort = true
    })

-- Diagnostic symbols in the sign column (gutter)
local signs = {Error = " ", Warn = " ", Hint = " ", Info = " "}
for type, icon in pairs(signs) do
    local hl = "DiagnosticSign" .. type
    vim.fn.sign_define(hl, {text = icon, texthl = hl, numhl = ""})
end

vim.diagnostic.config({
    virtual_text = {prefix = '●'},
    update_in_insert = true,
    float = {
        source = "always" -- Or "if_many"
    }
})

-----local augroup_lsp_document_highlight = vim.api.nvim_create_augroup("LspDocumentHighlight", { clear = true })
-- vim.api.nvim_create_autocmd("CursorHold", {
--  group = augroup_lsp_document_highlight,
--  command = [[vim.lsp.buf.document_highlight()]]
-- })
-- vim.api.nvim_create_autocmd("CursorHoldI", {
--  group = augroup_lsp_document_highlight,
--  command = [[vim.lsp.buf.document_highlight()]]
-- })
-- vim.api.nvim_create_autocmd("CursorMoved", {
--  group = augroup_lsp_document_highlight,
--  command = [[vim.lsp.buf.clear_references()]]
-- })
-- vim.api.nvim_create_autocmd("CursorMovedI", {
--  group = augroup_lsp_document_highlight,
--  command = [[vim.lsp.buf.clear_references()]]
-- })

-- setup
local coq = require('coq')

-- css
lspconfig.cssls.setup(coq.lsp_ensure_capabilities({}))
lspconfig.tailwindcss.setup(coq.lsp_ensure_capabilities({}))

-- lua
lspconfig.lua_ls.setup(coq.lsp_ensure_capabilities({
    settings = {
        Lua = {
            completion = {callSnippet = "Replace"},
            diagnostics = {
                -- Get the language server to recognize the `vim` global
                globals = {'vim'}
            },
            workspace = {
                -- Make the server aware of Neovim runtime files
                library = vim.api.nvim_get_runtime_file("", true),
                checkThirdParty = false
            }
        }
    }
}))

-- python
local function get_python_path(workspace)
    -- Use activated virtualenv.
    if vim.env.VIRTUAL_ENV then
        return util.path.join(vim.env.VIRTUAL_ENV, 'bin', 'python')
    end

    -- Find and use virtualenv in workspace directory.
    for _, pattern in ipairs({'*', '.*'}) do
        local match = vim.fn.glob(util.path.join(workspace, pattern,
                                                 'pyvenv.cfg'))
        if match ~= '' then
            return util.path.join(util.path.dirname(match), 'bin', 'python')
        end
    end

    -- Fallback to system Python.
    return exepath('python3') or exepath('python') or 'python'
end
lspconfig.pyright.setup(coq.lsp_ensure_capabilities({
    before_init = function(_, config)
        config.settings.python.pythonPath = get_python_path(config.root_dir)
    end,
    filetypes = {"python"}
    -- python = {pythonPath = "~/.pyenv/shims/python"}
}))

-- yaml
lspconfig.yamlls.setup(coq.lsp_ensure_capabilities({
    settings = {yaml = {keyOrdering = false}}
}))
