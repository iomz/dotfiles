local status, ts = pcall(require, "nvim-treesitter.configs")
if (not status) then return end

ts.setup {
  highlight = { enable = true, disable = { "html" } },
  indent = { enable = true, disable = {} },
  ensure_installed = {
    "bash", "css", "go", "json", "html", "lua", "markdown", "markdown_inline",
    "python", "toml", "tsx", "typescript", "yaml"
  },
  autotag = { enable = true },
  context_commentstring = { enable = true, enable_autocmd = false }
}

local parser_config = require "nvim-treesitter.parsers".get_parser_configs()
parser_config.tsx.filetype_to_parsername = { "javascript", "typescript.tsx" }
