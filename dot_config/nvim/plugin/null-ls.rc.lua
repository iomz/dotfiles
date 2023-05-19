local status, null_ls = pcall(require, "null-ls")
if (not status) then return end

local augroup = vim.api.nvim_create_augroup("LspFormatting", {})

local lsp_formatting = function(bufnr)
    vim.lsp.buf.format({
        filter = function(client) return client.name == "null-ls" end,
        bufnr = bufnr
    })
end

null_ls.setup {
    sources = {
        --
        -- diagnostics
        --
        null_ls.builtins.diagnostics.eslint_d.with({
            diagnostics_format = '[eslint] #{m}\n(#{c})'
        }), -- eslint
        null_ls.builtins.diagnostics.zsh, -- zsh
        --
        -- formatting
        --
        null_ls.builtins.formatting.beautysh, -- bash/zsh
        null_ls.builtins.formatting.black.with({
            extra_args = {"--line-length=120"}
        }), -- python
        null_ls.builtins.formatting.isort, -- python
        null_ls.builtins.formatting.gofmt, -- gofmt
        null_ls.builtins.formatting.lua_format, -- lua
        null_ls.builtins.formatting.prettierd -- web
    },
    on_attach = function(client, bufnr)
        if client.supports_method("textDocument/formatting") then
            vim.api.nvim_clear_autocmds({group = augroup, buffer = bufnr})
            vim.api.nvim_create_autocmd("BufWritePre", {
                group = augroup,
                buffer = bufnr,
                callback = function() lsp_formatting(bufnr) end
            })
        end
    end
}

vim.api.nvim_create_user_command('DisableLspFormatting', function()
    vim.api.nvim_clear_autocmds({group = augroup, buffer = 0})
end, {nargs = 0})
