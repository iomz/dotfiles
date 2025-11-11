-- vim.lsp.set_log_level("debug")

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

local blink_status, blink = pcall(require, "blink.cmp")
if (not blink_status) then return end

local capabilities = blink.get_lsp_capabilities()

-- Create format augroup once at module level
local format_augroup = vim.api.nvim_create_augroup("Format", { clear = true })

-- Function executed when the LSP server startup
local function on_attach(client, bufnr)
    -- Enable completion triggered by <c-x><c-o>
    vim.api.nvim_buf_set_option(bufnr, 'omnifunc', 'v:lua.vim.lsp.omnifunc')

    -- Mappings (mostly replaced by lspsaga)
    local keymap = vim.keymap.set
    local bufopts = { noremap = true, silent = true, buffer = bufnr }
    ---- See `:help vim.lsp.*` for documentation on any of the below functions
    keymap('n', '<leader>gD', "<cmd>lua vim.lsp.buf.declaration()<CR>", bufopts)
    keymap('n', '<leader>gi', "<cmd>lua vim.lsp.buf.implementation()<CR>", bufopts)
    keymap('n', '<leader>gr', "<cmd>lua vim.lsp.buf.references()<CR>", bufopts)
    --keymap('n', '<leader>D', vim.lsp.buf.type_definition, bufopts)
    keymap('n', '<leader>gf', '<cmd>lua vim.lsp.buf.format()<CR>', bufopts)
    keymap('n', '<leader>gwa', "<cmd>lua vim.lsp.buf.add_workspace_folder()<CR>", bufopts)
    keymap('n', '<leader>gwr', "<cmd>lua vim.lsp.buf.remove_workspace_folder()<CR>", bufopts)
    keymap('n', '<leader>gwl', function()
        print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
    end, bufopts)

    -- format on save (clear only this buffer's autocmds)
    -- Skip for Go files since they have their own goimports formatter
    local ft = vim.bo[bufnr].filetype
    if not vim.tbl_contains({ "go", "gomod" }, ft) then
        vim.api.nvim_clear_autocmds({ group = format_augroup, buffer = bufnr })
        vim.api.nvim_create_autocmd("BufWritePre", {
            group = format_augroup,
            buffer = bufnr,
            callback = function()
                vim.lsp.buf.format({ bufnr = bufnr, async = false })
            end
        })
    end
end

mason_lspconfig.setup({
    automatic_installation = true,
    ensure_installed = {
        "dockerls",      -- docker
        "denols",        -- manual setup below
        "eslint",        -- eslint
        "lua_ls",        -- lua
        "marksman",      -- markdown
        "pylsp",         -- python
        "ruff",          -- python
        "rust_analyzer", -- rust
        "ts_ls",         -- manual setup below
        "yamlls",        -- yaml
    },
})

-- Helper to get root patterns
local function root_pattern(...)
    local patterns = { ... }
    return function(fname)
        for _, pattern in ipairs(patterns) do
            local match = vim.fs.find(pattern, {
                upward = true,
                path = vim.fs.dirname(fname),
            })[1]
            if match then
                return vim.fs.dirname(match)
            end
        end
        return nil
    end
end

-- Configure LSP servers using vim.lsp.config
vim.lsp.config('gopls', {
    cmd = { "gopls", "serve" },
    filetypes = { "go", "gomod" },
    root_markers = { "go.work", "go.mod", ".git" },
    capabilities = capabilities,
    on_attach = on_attach,
    settings = {
        gopls = {
            analyses = {
                unusedparams = true,
            },
            staticcheck = true,
        },
    },
})

vim.lsp.config('lua_ls', {
    cmd = { "lua-language-server" },
    filetypes = { "lua" },
    root_markers = { ".luarc.json", ".luarc.jsonc", ".luacheckrc", ".stylua.toml", "stylua.toml", "selene.toml", "selene.yml", ".git" },
    capabilities = capabilities,
    on_attach = on_attach,
    settings = {
        Lua = {
            runtime = {
                version = 'LuaJIT',
            },
            diagnostics = {
                globals = { 'exepath', 'vim' },
            },
            workspace = {
                library = vim.api.nvim_get_runtime_file("", true),
                checkThirdParty = false
            },
            telemetry = {
                enable = false,
            },
        },
    },
})

vim.lsp.config('pylsp', {
    cmd = { "pylsp" },
    filetypes = { "python" },
    root_markers = { "pyproject.toml", "setup.py", "setup.cfg", "requirements.txt", "Pipfile", ".git" },
    capabilities = capabilities,
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
})

-- Simple servers with default config
local simple_servers = {
    'ruff',
    'dockerls',
    'marksman',
    'rust_analyzer',
    'yamlls',
    'eslint',
    'tailwindcss',
}

for _, server in ipairs(simple_servers) do
    vim.lsp.config(server, {
        capabilities = capabilities,
        on_attach = on_attach,
    })
end

-- Enable all configured servers
vim.lsp.enable({ 'gopls', 'lua_ls', 'pylsp', 'ruff', 'dockerls', 'marksman', 'rust_analyzer', 'yamlls', 'eslint',
    'tailwindcss' })

-- Note: ts_ls and denols are managed manually via autocommand below
-- They will be started with vim.lsp.start() instead of vim.lsp.config

-- Global flag to track which server should be allowed per buffer
_G.allowed_ts_server = {}

-- Clean up the table when buffers are deleted to prevent memory leaks
vim.api.nvim_create_autocmd("BufDelete", {
    callback = function(args)
        -- Clean up any buffer that might have been in the table
        _G.allowed_ts_server[args.buf] = nil
    end,
})

-- Kill unwanted LSP servers immediately on attach
vim.api.nvim_create_autocmd("LspAttach", {
    callback = function(args)
        local bufnr = args.buf
        local client = vim.lsp.get_client_by_id(args.data.client_id)
        if not client then return end

        local fname = vim.api.nvim_buf_get_name(bufnr)
        local ft = vim.bo[bufnr].filetype

        -- Only handle TypeScript/JavaScript files
        if not vim.tbl_contains({ "typescript", "typescriptreact", "javascript", "javascriptreact" }, ft) then
            return
        end

        local allowed = _G.allowed_ts_server[bufnr]

        if (client.name == "ts_ls" and allowed ~= "ts_ls") or
            (client.name == "denols" and allowed ~= "denols") then
            vim.schedule(function()
                client.stop()
            end)
        end
    end,
})

-- Go-specific format on save (in addition to LSP formatting)
local format_sync_grp = vim.api.nvim_create_augroup("GoFormat", {})
vim.api.nvim_create_autocmd("BufWritePre", {
    pattern = "*.go",
    callback = function()
        require('go.format').goimports()
    end,
    group = format_sync_grp,
})

-- See: https://github.com/neovim/nvim-lspconfig/tree/54eb2a070a4f389b1be0f98070f81d23e2b1a715#suggested-configuration
local keymap = vim.keymap.set
local opts = { noremap = true, silent = true }
keymap('n', '[d', "<cmd>lua vim.diagnostic.goto_prev()<CR>", opts)
keymap('n', ']d', "<cmd>lua vim.diagnostic.goto_next()<CR>", opts)
keymap('n', '<leader>e', "<cmd>lua vim.diagnostic.open_float()<CR>", opts)
keymap('n', '<leader>q', "<cmd>lua vim.diagnostic.setloclist()<CR>", opts)

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

-- ts_ls and denols with mutual exclusion via autocommands
-- This must be at the end after on_attach is defined

-- First, set the allowed server flag on FileType (before LSP servers start)
-- This autocmd is defined first so it runs before the one below that starts LSP servers
vim.api.nvim_create_autocmd("FileType", {
    pattern = { "typescript", "typescriptreact", "javascript", "javascriptreact" },
    callback = function()
        local bufnr = vim.api.nvim_get_current_buf()
        local fname = vim.api.nvim_buf_get_name(bufnr)

        -- Check which project type
        local is_deno = root_pattern("deno.json", "deno.jsonc")(fname)
        local is_node = root_pattern(
            'package.json',
            'package-lock.json',
            'pnpm-lock.yaml',
            'yarn.lock',
            'bun.lockb',
            'node_modules'
        )(fname)

        -- Set the flag FIRST before any LSP servers start
        if is_deno and not is_node then
            _G.allowed_ts_server[bufnr] = "denols"
        elseif is_node and not is_deno then
            _G.allowed_ts_server[bufnr] = "ts_ls"
        end
    end,
})

-- Then, start the appropriate LSP server
vim.api.nvim_create_autocmd("FileType", {
    pattern = { "typescript", "typescriptreact", "javascript", "javascriptreact" },
    callback = function()
        local bufnr = vim.api.nvim_get_current_buf()
        local fname = vim.api.nvim_buf_get_name(bufnr)
        local allowed = _G.allowed_ts_server[bufnr]

        if allowed == "denols" then
            -- Start denols
            local root_dir = root_pattern("deno.json", "deno.jsonc")(fname)
            vim.lsp.start({
                name = "denols",
                cmd = { "deno", "lsp" },
                root_dir = root_dir,
                capabilities = capabilities,
                on_attach = on_attach,
                settings = {
                    deno = {
                        enable = true,
                        suggest = {
                            imports = {
                                hosts = {
                                    ["https://deno.land"] = true,
                                    ["https://cdn.nest.land"] = true,
                                    ["https://crux.land"] = true,
                                },
                            },
                        },
                    },
                },
                init_options = {
                    lint = true,
                    unstable = true,
                },
            })
        elseif allowed == "ts_ls" then
            -- Start ts_ls
            local root_dir = root_pattern(
                'package.json',
                'package-lock.json',
                'pnpm-lock.yaml',
                'yarn.lock',
                'bun.lockb',
                'node_modules'
            )(fname)
            vim.lsp.start({
                name = "ts_ls",
                cmd = { "typescript-language-server", "--stdio" },
                root_dir = root_dir,
                capabilities = capabilities,
                on_attach = on_attach,
                init_options = {
                    hostInfo = "neovim"
                },
            })
        end
    end,
})
