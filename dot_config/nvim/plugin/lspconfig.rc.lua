-- vim.lsp.set_log_level("debug")
local status, lspconfig = pcall(require, "lspconfig")
if (not status) then return end

local mason_status, mason = pcall(require, "mason")
if (not mason_status) then return end
mason.setup({
    ui = {
        icons = {
            package_installed = '✓',
            package_pending = '➜',
            package_uninstalled = '✗'
        }
    }
})

local mason_lspconfig_status, mason_lspconfig = pcall(require, "mason-lspconfig")
if (not mason_lspconfig_status) then return end

mason_lspconfig.setup({
    automatic_installation = true,
    ensure_installed = { "beautysh", "black", "lua_ls" },
})

local coq_status, coq = pcall(require, "coq")
if (not coq_status) then return end

-- format on save
local augroup_format = vim.api.nvim_create_augroup("Format", { clear = true })
local enable_format_on_save = function(_, bufnr)
    vim.api.nvim_clear_autocmds({ group = augroup_format, buffer = bufnr })
    vim.api.nvim_create_autocmd("BufWritePre", {
        group = augroup_format,
        buffer = bufnr,
        callback = function() vim.lsp.buf.format({ bufnr = bufnr }) end
    })
end

-- Function executed when the LSP server startup
local on_attach = function(client, bufnr)
    -- Enable completion
    local function buf_set_option(...)
        vim.api.nvim_buf_set_option(bufnr, ...)
    end
    buf_set_option('omnifunc', 'v:lua.vim.lsp.omnifunc')

    -- Mappings
    local function buf_set_keymap(...)
        vim.api.nvim_buf_set_keymap(bufnr, ...)
    end
    local opts = { noremap = true, silent = true }
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
    buf_set_keymap('i', '<c-k>', '<cmd>lua vim.lsp.buf.signature_help()<CR>', opts)

    -- format
    enable_format_on_save(client, bufnr)
end

mason_lspconfig.setup_handlers({
    function(server)
        lspconfig[server].setup(coq.lsp_ensure_capabilities({
            on_attach = on_attach
        }))
    end,
    -- css
    --lspconfig.cssls.setup({})
    --lspconfig.tailwindcss.setup({})
    -- lua
    ["lua_ls"] = function()
        lspconfig.lua_ls.setup(coq.lsp_ensure_capabilities({
            on_attach = on_attach,
            settings = {
                Lua = {
                    runtime = {
                        -- Tell the language server which version of Lua you're using (most likely LuaJIT in the case of Neovim)
                        version = 'LuaJIT',
                    },
                    diagnostics = {
                        -- Get the language server to recognize the `vim` global
                        globals = { 'exepath', 'vim' },
                    },
                    workspace = {
                        -- Make the server aware of Neovim runtime files
                        library = vim.api.nvim_get_runtime_file("", true),
                        checkThirdParty = false
                    },
                    -- Do not send telemetry data containing a randomized but unique identifier
                    telemetry = {
                        enable = false,
                    },
                },
            },
        }))
    end,
    -- python
    ["pyright"] = function()
        local util = require('lspconfig/util')
        local function get_python_path(workspace)
            -- Use activated virtualenv.
            if vim.env.VIRTUAL_ENV then
                return util.path.join(vim.env.VIRTUAL_ENV, 'bin', 'python')
            end
            -- Find and use virtualenv in workspace directory.
            for _, pattern in ipairs({ '*', '.*' }) do
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
            filetypes = { "python" },
            on_attach = on_attach
        }))
    end,
    -- yaml
    ["yamlls"] = function()
        lspconfig.yamlls.setup(coq.lsp_ensure_capabilities({
            on_attach = on_attach,
            settings = { yaml = { keyOrdering = false } }
        }))
    end
})

-- on_publish_diagnostics
vim.lsp.handlers["textDocument/publishDiagnostics"] =
    vim.lsp.with(vim.lsp.diagnostic.on_publish_diagnostics, {
        underline = true,
        update_in_insert = true,
        virtual_text = { spacing = 4, prefix = "●" },
        severity_sort = true
    })

-- DiagnosticSign in the gutter
local signs = { Error = " ", Warn = " ", Hint = " ", Info = " " }
for type, icon in pairs(signs) do
    local hl = "DiagnosticSign" .. type
    vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = "" })
end

vim.diagnostic.config({
    virtual_text = { prefix = '●' },
    update_in_insert = true,
    float = {
        source = "always" -- Or "if_many"
    }
})

-- protocol.CompletionItemKind
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
