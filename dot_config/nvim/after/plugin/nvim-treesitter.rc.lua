local status, ts = pcall(require, "nvim-treesitter.configs")
if (not status) then return end


ts.setup {
    -- Install parsers synchronously (only applied to `ensure_installed`)
    sync_install = false,

    -- Automatically install missing parsers when entering buffer
    -- Recommendation: set to false if you don't have `tree-sitter` CLI installed locally
    auto_install = true,

    -- List of parsers to ignore installing (or "all")
    ignore_install = {},

    context_commentstring = { enable = true, enable_autocmd = false },
    ensure_installed = {
        "bash", "css", "go", "javascript", "json", "html", "lua", "markdown", "markdown_inline",
        "python", "toml", "tsx", "typescript", "yaml"
    },
    highlight = { enable = true },
    indent = { enable = true, disable = {} },
    -- matchup = {
    --     enable = true, -- mandatory, false will disable the whole extension
    --     --disable = { "c", "ruby" },  -- optional, list of language that will be disabled
    --     -- [options]
    -- },
}

--local parser_config = require "nvim-treesitter.parsers".get_parser_configs()
--parser_config.tsx.filetype_to_parsername = { "javascript", "typescript.tsx" }
