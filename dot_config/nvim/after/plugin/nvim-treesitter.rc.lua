local status, ts = pcall(require, "nvim-treesitter")
if (not status) then return end

ts.setup {}
ts.install {
    "bash", "css", "go", "javascript", "json", "html", "lua", "markdown", "markdown_inline",
    "python", "toml", "tsx", "typescript", "yaml"
}

vim.api.nvim_create_autocmd('FileType', {
    group = vim.api.nvim_create_augroup('TreesitterSetup', { clear = true }),
    callback = function(event)
        local lang = vim.treesitter.language.get_lang(vim.bo[event.buf].filetype)
        if not lang or not vim.treesitter.language.add(lang) then return end

        vim.treesitter.start(event.buf, lang)
        vim.bo[event.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
    end,
})
