--
-- plugins for lazy.vim
--
return {
    -- autoclose; auto pairs & close brackets
    {
        'm4xshen/autoclose.nvim',
        config = function() require('autoclose').setup() end
    },
    -- avante: the AI coding agent
    {
        "yetone/avante.nvim",
        -- if you want to build from source then do `make BUILD_FROM_SOURCE=true`
        -- ⚠️ must add this setting! ! !
        build = vim.fn.has("win32") ~= 0
            and "powershell -ExecutionPolicy Bypass -File Build.ps1 -BuildFromSource false"
            or "make",
        event = "VeryLazy",
        version = false, -- Never set this value to "*"! Never!
        ---@module 'avante'
        ---@type avante.Config
        opts = {
            -- add any opts here
            -- this file can contain specific instructions for your project
            instructions_file = "avante.md",
            -- for example
            provider = "claude",
            providers = {
                claude = {
                    endpoint = "https://api.anthropic.com",
                    model = "claude-sonnet-4-20250514",
                    timeout = 30000, -- Timeout in milliseconds
                    extra_request_body = {
                        temperature = 0.75,
                        max_tokens = 20480,
                    },
                },
            },
        },
        dependencies = {
            "nvim-lua/plenary.nvim",
            "MunifTanjim/nui.nvim",
            --- The below dependencies are optional,
            "nvim-mini/mini.pick",           -- for file_selector provider mini.pick
            "nvim-telescope/telescope.nvim", -- for file_selector provider telescope
            "hrsh7th/nvim-cmp",              -- autocompletion for avante commands and mentions
            "ibhagwan/fzf-lua",              -- for file_selector provider fzf
            "stevearc/dressing.nvim",        -- for input provider dressing
            "folke/snacks.nvim",             -- for input provider snacks
            "nvim-tree/nvim-web-devicons",   -- or echasnovski/mini.icons
            "zbirenbaum/copilot.lua",        -- for providers='copilot'
            {
                -- support for image pasting
                "HakonHarnes/img-clip.nvim",
                event = "VeryLazy",
                opts = {
                    -- recommended settings
                    default = {
                        embed_image_as_base64 = false,
                        prompt_for_file_name = false,
                        drag_and_drop = {
                            insert_mode = true,
                        },
                        -- required for Windows users
                        use_absolute_path = true,
                    },
                },
            },
            {
                -- Make sure to set this up properly if you have lazy=true
                'MeanderingProgrammer/render-markdown.nvim',
                opts = {
                    file_types = { "markdown", "Avante" },
                },
                ft = { "markdown", "Avante" },
            },
        },
    },
    -- bclose: for tig-explorer
    'rbgrouleff/bclose.vim',
    -- snazzy buffer line
    {
        'akinsho/bufferline.nvim',
        dependencies = { 'nvim-tree/nvim-web-devicons' }
    },
    -- blink.cmp: modern completion engine
    {
        'Saghen/blink.cmp',
        version = '1.*',
        event = { 'InsertEnter', 'CmdlineEnter' },
        dependencies = {
            'rafamadriz/friendly-snippets',
            {
                'L3MON4D3/LuaSnip',
                version = 'v2.*',
                build = 'make install_jsregexp',
                config = function()
                    require('luasnip.loaders.from_vscode').lazy_load()
                end,
            },
        },
        opts = {
            keymap = { preset = 'super-tab' },
            appearance = {
                nerd_font_variant = 'mono',
            },
            completion = {
                documentation = { auto_show = true },
                ghost_text = {
                    enabled = true,
                    show_with_menu = true,
                },
            },
            snippets = {
                preset = 'luasnip',
            },
            sources = {
                default = { 'lsp', 'path', 'snippets', 'buffer' },
            },
            fuzzy = {
                implementation = 'prefer_rust_with_warning',
            },
        },
        opts_extend = { 'sources.default' },
    },
    -- {
    --     "olimorris/codecompanion.nvim",
    --     dependencies = {
    --         "nvim-lua/plenary.nvim",
    --         "nvim-treesitter/nvim-treesitter",
    --     },
    --     opts = {
    --         -- NOTE: The log_level is in `opts.opts`
    --         opts = {
    --             log_level = "DEBUG", -- or "TRACE"
    --         },
    --     },
    -- },
    -- comfortable-motion: smooth scroll
    -- 'yuttie/comfortable-motion.vim',
    -- smart comment
    --{
    --    'numToStr/Comment.nvim',
    --    config = function() require('Comment').setup() end,
    --    dependencies = { 'JoosepAlviste/nvim-ts-context-commentstring' }
    --},
    -- coplilot
    -- 'github/copilot.vim',
    -- turn browsers into nvim clients
    {
        'glacambre/firenvim',
        build = function() vim.fn['firenvim#install'](0) end
    },
    -- git-signs: show git diff
    {
        'lewis6991/gitsigns.nvim',
        dependencies = { 'nvim-lua/plenary.nvim' },
        config = function() require('gitsigns').setup() end
    },
    -- go
    {
        "ray-x/go.nvim",
        dependencies = { -- optional packages
            "ray-x/guihua.lua",
            "neovim/nvim-lspconfig",
            "nvim-treesitter/nvim-treesitter",
        },
        config = function()
            require("go").setup()
        end,
        event = { "CmdlineEnter" },
        ft = { "go", 'gomod' },
        build = ':lua require("go.install").update_all_sync()' -- if you need to install/update all binaries
    },
    -- just another quick run
    "is0n/jaq-nvim",
    -- lazygit
    {
        "iomz/lazygit.nvim",
        branch = 'remove-oldshell',
        -- optional for floating window border decoration
        dependencies = {
            "nvim-lua/plenary.nvim",
        },
    },
    -- vscode-like pictograms for built-in lsp
    'onsails/lspkind-nvim',
    -- LSP UIs
    'glepnir/lspsaga.nvim',
    -- statusline
    'nvim-lualine/lualine.nvim',
    -- preview markdown
    {
        'iamcco/markdown-preview.nvim',
        build = ':call mkdp#util#install()',
        ft = 'markdown'
    },
    -- mason: lsp server management
    {
        'williamboman/mason.nvim',
        build = function() require('mason.api.command').MasonUpdate() end,
        dependencies = {
            'williamboman/mason-lspconfig.nvim',-- mason-lspconfig
            'neovim/nvim-lspconfig',            -- nvim-lspconfig
        }
    },                                          --
    -- mason-null-ls: ensure none-ls(null-ls) installations
    {
        "jay-babu/mason-null-ls.nvim",
        event = { "BufReadPre", "BufNewFile" },
        dependencies = {
            "williamboman/mason.nvim",
            "nvimtools/none-ls.nvim",
        }
    },
    -- matchparen
    {
        'monkoose/matchparen.nvim',
        config = function()
            require('matchparen').setup({
                enabled = true,           -- enable plugin on startup
                hl_group = 'MatchParen',  -- highlight group of the matched brackets
                debounce_time = 0,        -- debounce time in milliseconds for rehighlighting of brackets
            })
        end,
    },
    -- minimap
    {
        'wfxr/minimap.vim',
        build = 'cargo install --locked code-minimap'
    },
    -- mini.icons
    {
        'echasnovski/mini.icons',
        version = '*'
    },
    -- molokai colorscheme
    {
        'tomasr/molokai'
        -- config = function() vim.cmd [[colorscheme molokai]] end
    },
    -- nvim dev config for lua-ls
    -- 'folke/neodev.nvim',
    -- neoterm: access terminal with :T
    -- 'kassio/neoterm',
    -- neotest
    {
        'nvim-neotest/neotest',
        dependencies = {
            'nvim-neotest/nvim-nio',
            'nvim-lua/plenary.nvim',
            'antoinemadec/FixCursorHold.nvim',
            'nvim-treesitter/nvim-treesitter'
        },
    },
    'nvim-neotest/neotest-python',
    'nvim-neotest/neotest-plenary',
    'nvim-neotest/neotest-vim-test',
    -- nerdtree: filesystem explorer
    'scrooloose/nerdtree',
    -- nightfox colorshceme
    {
        'EdenEast/nightfox.nvim'
        -- config = function() vim.cmd [[colorscheme carbonfox]] end
    },
    -- inject LSP diagnostics, code actions, and more via Lua
    { 'nvimtools/none-ls.nvim' },
    -- autopair: https://github.com/windwp/nvim-autopairs
    --'windwp/nvim-autopairs',
    -- base16
    {
        'RRethy/nvim-base16',
        -- config = function() vim.cmd [[colorscheme base16-everforest]] end
        -- config = function() vim.cmd [[colorscheme base16-horizon-terminal-dark]] end
        config = function() vim.cmd [[colorscheme base16-oceanicnext]] end
        -- config = function() vim.cmd [[colorscheme base16-paraiso]] end
        -- config = function() vim.cmd [[colorscheme base16-phd]] end
        -- config = function() vim.cmd [[colorscheme base16-seti]] end
        -- config = function() vim.cmd [[colorscheme base16-snazzy]] end
        -- config = function() vim.cmd [[colorscheme base16-solarflare]] end
        -- config = function() vim.cmd [[colorscheme base16-tokyo-city-dark]] end
        -- config = function() vim.cmd [[colorscheme base16-tomorrow-night]] end
        -- config = function() vim.cmd [[colorscheme base16-tomorrow-night-eighties]] end
        -- config = function() vim.cmd [[colorscheme base16-twilight]] end
    },
    -- superspeed colorizer
    {
        'norcalli/nvim-colorizer.lua',
        config = function() require('colorizer').setup({ '*' }) end
    },
    -- nvim-dap: debug adapter protocol client
    -- {
    --  'mfussenegger/nvim-dap',
    --  dependencies = {
    --    'rcarriga/nvim-dap-ui',
    --    'theHamsta/nvim-dap-virtual-text',
    --  }
    -- },
    -- nvim-spectre: find the enemy and replace them with dark power
    {
        'nvim-pack/nvim-spectre',
        config = function()
            require('spectre').setup({
                is_block_ui_break = true,
                -- default = {
                --     replace = {
                --         cmd = "sed"
                --     }
                -- }
            })
        end
    },
    -- nvim-treesitter
    {
        'nvim-treesitter/nvim-treesitter',
        build = {
            'cargo install tree-sitter-cli', function()
            -- require('nvim-treesitter.install').compilers = { 'clang++'} -- for macOS
            require('nvim-treesitter.install').update { with_sync = true }
        end
        },
        dependencies = { 'nvim-treesitter/nvim-treesitter-context' }
    },
    -- nvim tree-sitter autotag
    {
        'windwp/nvim-ts-autotag',
        event = 'InsertEnter'
    },
    -- <-> vim-devicons
    'nvim-tree/nvim-web-devicons',
    -- plenary: a Lua module for asynchronous programming using coroutines
    'nvim-lua/plenary.nvim',
    -- sonictemplate: quick template with :Template
    'mattn/sonictemplate-vim',
    -- tagbar
    'preservim/tagbar',
    -- telescope
    {
        'nvim-telescope/telescope.nvim',
        dependencies = {
            -- telescope fzf
            { 'nvim-telescope/telescope-fzf-native.nvim', build = 'make' },
            'nvim-telescope/telescope-file-browser.nvim',
            'nvim-lua/plenary.nvim'
        }
    },
    -- tig: git client
    'iberianpig/tig-explorer.vim',
    -- toggleterm
    --{
    --    'akinsho/toggleterm.nvim',
    --    version = "*",
    --    config = true
    --},
    -- transparent
    'xiyaowong/transparent.nvim',
    -- trouble.nvim
    {
        "folke/trouble.nvim",
        opts = {}, -- for default options, refer to the configuration section for custom setup.
        cmd = "Trouble",
        keys = {
            {
                "<leader>xx",
                "<cmd>Trouble diagnostics toggle<cr>",
                desc = "Diagnostics (Trouble)",
            },
            {
                "<leader>xX",
                "<cmd>Trouble diagnostics toggle filter.buf=0<cr>",
                desc = "Buffer Diagnostics (Trouble)",
            },
            {
                "<leader>cs",
                "<cmd>Trouble symbols toggle focus=false<cr>",
                desc = "Symbols (Trouble)",
            },
            {
                "<leader>cl",
                "<cmd>Trouble lsp toggle focus=false win.position=right<cr>",
                desc = "LSP Definitions / references / ... (Trouble)",
            },
            {
                "<leader>xL",
                "<cmd>Trouble loclist toggle<cr>",
                desc = "Location List (Trouble)",
            },
            {
                "<leader>xQ",
                "<cmd>Trouble qflist toggle<cr>",
                desc = "Quickfix List (Trouble)",
            },
        },
    },
    -- vim-closer
    -- 'rstacruz/vim-closer',
    -- vim-closetag: for html tags
    'alvan/vim-closetag',
    -- comment stuff out with gcc/gc
    'tpope/vim-commentary',
    -- <-> nvim-web-devicons
    -- 'ryanoasis/vim-devicons',
    -- vim-easy-align: align with ga
    -- show test coveragee
    -- {
    --     'google/vim-coverage',
    --     dependencies = { 'google/vim-maktaba', 'google/vim-glaive' },
    --     build = ':call glaive#Install()',
    -- },
    'junegunn/vim-easy-align',
    -- dispatch compiler plugins
    {
        'tpope/vim-dispatch',
        cmd = { 'Dispatch', 'Make', 'Focus', 'Start' }
    },
    -- vim-gitgutter
    { 'airblade/vim-gitgutter' },
    -- matchup with texts
    --{ 'andymass/vim-matchup',  event = 'VimEnter' },
    -- markdown-toc
    { 'mzlogin/vim-markdown-toc' },
    -- vim-renamer
    'qpkorr/vim-renamer',
    -- vim-sensible: starting point config
    -- 'tpope/vim-sensible',
    -- vim-startify: fancy startup screen
    'mhinz/vim-startify',
    -- vim-surrond: parentheses, brackets, quotes, XML tags, and more
    --'tpope/vim-surround',
    -- vim-trailing-whitespace: mark trailing whitespace
    'bronson/vim-trailing-whitespace',
    -- vimproc
    {
        'Shougo/vimproc.vim',
        build = 'make'
    },
    -- wakatime
    'wakatime/vim-wakatime',
    -- which-key popup
    {
        'folke/which-key.nvim',
        config = function()
            vim.o.timeout = true
            vim.o.timeoutlen = 300
            require('which-key').setup {
                -- your configuration comes here
                -- or leave it empty to the default settings
                -- refer to the configuration section below
            }
        end
    },
    -- winresizer: can resize windows
    'simeji/winresizer',
    -- yankring: clipboard history
    -- {
    --    'vim-scripts/YankRing.vim',
    --    config = function()
    --        vim.g.yankring_history_dir = '$HOME/.cache/nvim'
    --        vim.g.yankring_replace_n_pkey = '<A-p>' -- don't <C-p>
    --    end
    -- },
    -- zenmode
    'folke/zen-mode.nvim'
}
