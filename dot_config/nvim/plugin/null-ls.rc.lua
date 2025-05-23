local status, null_ls = pcall(require, "null-ls")
if (not status) then return end

local augroup = vim.api.nvim_create_augroup("LspFormatting", {})

local lsp_formatting = function(bufnr)
    vim.lsp.buf.format({
        filter = function(client) return client.name == "null-ls" end,
        bufnr = bufnr
    })
end

local mason_null_ls_status, mason_null_ls = pcall(require, "mason-null-ls")
if (not mason_null_ls_status) then return end

mason_null_ls.setup({
    automatic_setup = true,
    ensure_installed = {
        "beautysh",                    -- bash/zsh
        "black",                       -- python
        "clang_format",                -- c++
        "golines",                     -- go
        "prettierd",                   -- web
        "tailwindcss-language-server", -- css
        "vale",                        -- latex
        "yamlfmt",                     -- yaml
        "xmlformat",                   -- xml
    }
})

null_ls.setup({
    sources = {
        --
        -- diagnostics
        --
        --null_ls.builtins.diagnostics.eslint_d.with({
        --    diagnostics_format = '[eslint_d] #{m}\n(#{c})'
        --}),                                         -- eslint_d
        -- null_ls.builtins.diagnostics.golangci_lint, -- go
        null_ls.builtins.diagnostics.vale.with({
            filetypes = { "tex" },
        }),                               -- latex
        null_ls.builtins.diagnostics.zsh, -- zsh
        --
        -- formatting
        --
        null_ls.builtins.formatting.black.with({ -- python
            extra_args = { "--line-length=120" }
        }),
        null_ls.builtins.formatting.clang_format, -- c++
        --null_ls.builtins.formatting.golines,      -- go
        --null_ls.builtins.formatting.latexindent,  -- latex
        null_ls.builtins.formatting.prettierd, -- web
        null_ls.builtins.formatting.yamlfmt,   -- yaml
        --null_ls.builtins.formatting.beautysh,    -- bash/zsh
        --null_ls.builtins.formatting.xmlformat,    -- xml
    },
    on_attach = function(client, bufnr)
        if client.supports_method("textDocument/formatting") then
            vim.api.nvim_clear_autocmds({ group = augroup, buffer = bufnr })
            vim.api.nvim_create_autocmd("BufWritePre", {
                group = augroup,
                buffer = bufnr,
                callback = function() lsp_formatting(bufnr) end
            })
        end
    end
})

-- TODO: fix this
vim.api.nvim_create_user_command('DisableLspFormatting', function()
    vim.api.nvim_clear_autocmds({ group = augroup, buffer = 0 })
end, { nargs = 0 })
