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
    ensure_installed = {
        "cssls",         -- css
        "tailwindcss",   -- css
        "dockerls",      -- docker
        "gopls",         -- go
        "lua_ls",        -- lua
        "marksman",      -- markdown
        "pylsp",         -- python
        "ruff_lsp",      -- python
        "rust_analyzer", -- rust
        "yamlls",        -- yaml
    },
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

-- See: https://github.com/neovim/nvim-lspconfig/tree/54eb2a070a4f389b1be0f98070f81d23e2b1a715#suggested-configuration
local keymap = vim.keymap.set
local opts = { noremap = true, silent = true }
keymap('n', '[d', "<cmd>lua vim.diagnostic.goto_prev()<CR>", opts)
keymap('n', ']d', "<cmd>lua vim.diagnostic.goto_next()<CR>", opts)
keymap('n', '<leader>e', "<cmd>lua vim.diagnostic.open_float()<CR>", opts)
keymap('n', '<leader>q', "<cmd>lua vim.diagnostic.setloclist()<CR>", opts)

-- Function executed when the LSP server startup
local on_attach = function(client, bufnr)
    -- Enable completion triggered by <c-x><c-o>
    vim.api.nvim_buf_set_option(bufnr, 'omnifunc', 'v:lua.vim.lsp.omnifunc')

    -- Mappings (mostly replaced by lspsaga)
    local bufopts = { noremap = true, silent = true, buffer = bufnr }
    ---- See `:help vim.lsp.*` for documentation on any of the below functions
    keymap('n', '<leader>gD', "<cmd>lua vim.lsp.buf.declaration()<CR>", bufopts)
    keymap('n', '<leader>gi', "<cmd>lua vim.lsp.buf.implementation()<CR>", bufopts)
    keymap('n', '<leader>gr', "<cmd>lua vim.lsp.buf.references()<CR>", bufopts)
    --keymap('n', '<leader>D', vim.lsp.buf.type_definition, bufopts)
    keymap('n', '<leader>gf', '<cmd>lua vim.lsp.buf.formatting()<CR>', bufopts)
    keymap('n', '<leader>gwa', "<cmd>lua vim.lsp.buf.add_workspace_folder()<CR>", bufopts)
    keymap('n', '<leader>gwr', "<cmd>lua vim.lsp.buf.remove_workspace_folder()<CR>", bufopts)
    keymap('n', '<leader>gwl', function()
        print(vim.inspect(vim.lsp.buf.list_workleader_folders()))
    end, bufopts)

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
    ["cssls"] = function()
        lspconfig.cssls.setup(coq.lsp_ensure_capabilities({
            on_attach = on_attach
        }))
    end,
    ["tailwindcss"] = function()
        lspconfig.tailwindcss.setup(coq.lsp_ensure_capabilities({
            on_attach = on_attach
        }))
    end,
    -- go
    ["gopls"] = function()
        local util = require('lspconfig/util')
        lspconfig.gopls.setup(coq.lsp_ensure_capabilities({
            on_attach = on_attach,
            cmd = { "gopls", "serve" },
            filetypes = { "go", "gomod" },
            root_dir = util.root_pattern("go.work", "go.mod", ".git"),
            settings = {
                gopls = {
                    analyses = {
                        unusedparams = true,
                    },
                    staticcheck = true,
                },
            },
        }))
    end,
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
    -- https://github.com/neovim/nvim-lspconfig/blob/master/doc/server_configurations.md#pylsp
    ["pylsp"] = function()
        lspconfig.pylsp.setup(coq.lsp_ensure_capabilities({
            on_attach = on_attach,
            settings = {
                pylsp = {
                    plugins = {
                        mccabe = {
                            enabled = false,
                        },
                        pycodestyle = {
                            ignore = { 'E203', 'W391', 'W503' },
                            maxLineLength = 120
                        },
                        pyflakes = {
                            enabled = false,
                        },
                    }
                }
            }
        }))
    end,
    -- https://github.com/neovim/nvim-lspconfig/blob/master/doc/server_configurations.md#ruff_lsp
    ["ruff_lsp"] = function()
        lspconfig.ruff_lsp.setup(coq.lsp_ensure_capabilities({
            on_attach = on_attach,
            --init_otions = {
            --    settings = {
            --        args = {},
            --    }
            --}
        }))
    end,
    --["pyright"] = function()
    --    local util = require('lspconfig/util')
    --    local function get_python_path(workspace)
    --        -- Use activated virtualenv.
    --        if vim.env.VIRTUAL_ENV then
    --            return util.path.join(vim.env.VIRTUAL_ENV, 'bin', 'python')
    --        end
    --        -- Find and use virtualenv in workspace directory.
    --        for _, pattern in ipairs({ '*', '.*' }) do
    --            local match = vim.fn.glob(util.path.join(workspace, pattern,
    --                'pyvenv.cfg'))
    --            if match ~= '' then
    --                return util.path.join(util.path.dirname(match), 'bin', 'python')
    --            end
    --        end
    --        -- Fallback to system Python.
    --        return exepath('python3') or exepath('python') or 'python'
    --    end
    --    lspconfig.pyright.setup(coq.lsp_ensure_capabilities({
    --        before_init = function(_, config)
    --            config.settings.python.pythonPath = get_python_path(config.root_dir)
    --        end,
    --        filetypes = { "python" },
    --        on_attach = on_attach
    --    }))
    --end,
    -- yaml
    --["yamlls"] = function()
    --    lspconfig.yamlls.setup(coq.lsp_ensure_capabilities({
    --        on_attach = on_attach,
    --        settings = { yaml = { keyOrdering = false } }
    --    }))
    --end
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
vim.diagnostic.config({
    signs = {
        text = {
            [vim.diagnostic.severity.ERROR] = " ",
            [vim.diagnostic.severity.WARN] = " ",
            [vim.diagnostic.severity.HINT] = " ",
            [vim.diagnostic.severity.INFO] = " ",
        },
    },
    virtual_text = { prefix = '●' },
    update_in_insert = false,
    underline = true,
    severity_sort = true,
    float = {
        focusable = true,
        style = "minimal",
        border = "rounded",
        header = "",
        prefix = "",
        source = true,
    },
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
