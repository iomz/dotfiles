--
-- Plugins
--
local ensure_packer = function()
    local fn = vim.fn
    local install_path = fn.stdpath('data') ..
                             '/site/pack/packer/start/packer.nvim'
    if fn.empty(fn.glob(install_path)) > 0 then
        fn.system({
            'git', 'clone', '--depth', '1',
            'https://github.com/wbthomason/packer.nvim', install_path
        })
        vim.cmd [[packadd packer.nvim]]
        return true
    end
    return false
end

local packer_bootstrap = ensure_packer()

return require('packer').startup(function(use)
    use 'wbthomason/packer.nvim' -- manage itself

    use 'rbgrouleff/bclose.vim' -- bclose: for tig-explorer
    use { -- snazzy buffer line
        'akinsho/bufferline.nvim',
        tag = "*",
        requires = 'nvim-tree/nvim-web-devicons'
    }

    -- use 'yuttie/comfortable-motion.vim' -- comfortable-motion: smooth scroll
    use { -- smart comment
        'numToStr/Comment.nvim',
        config = function() require('Comment').setup() end,
        requires = {'JoosepAlviste/nvim-ts-context-commentstring'}
    }
    -- use 'github/copilot.vim' -- coplilot
    use { -- coq_nvim: another coc
        'ms-jpq/coq_nvim',
        branch = 'coq',
        requires = {'neovim/nvim-lspconfig'}
    }
    use { -- 9000+ Snippets
        'ms-jpq/coq.artifacts',
        branch = 'artifacts'
    }
    use { -- lua & third party sources -- See https://github.com/ms-jpq/coq.thirdparty
        'ms-jpq/coq.thirdparty',
        branch = '3p',
        config = function() require('coq_3p') end
    }

    use { -- turn browsers into nvim clients
        'glacambre/firenvim',
        run = function() vim.fn['firenvim#install'](0) end
    }

    use { -- git-signs: show git diff
        'lewis6991/gitsigns.nvim',
        requires = {'nvim-lua/plenary.nvim'},
        config = function() require('gitsigns').setup() end
    }
    -- use 'junegunn/gv.vim' -- gv: git commit browser

    use 'onsails/lspkind-nvim' -- vscode-like pictograms for built-in lsp
    use 'glepnir/lspsaga.nvim' -- LSP UIs
    use 'nvim-lualine/lualine.nvim' -- statusline
    -- use 'L3MON4D3/LuaSnip' -- snippets
    -- use { -- preview markdown
    --  'iamcco/markdown-preview.nvim',
    --  run = function() vim.fn["mkdp#util#install"]() end,
    --  cmd = 'MarkdownPreview'
    -- }

    use { -- mason: lsp server management
        'williamboman/mason.nvim',
        run = function() require('mason.api.command').MasonUpdate() end,
        requires = {
            'neovim/nvim-lspconfig', -- nvim-lspconfig
            'williamboman/mason-lspconfig.nvim'
        }
    }
    use { -- minimap
        'wfxr/minimap.vim',
        run = 'cargo install --locked code-minimap'
    }
    use { -- molokai colorscheme
        'tomasr/molokai'
        -- config = 'vim.cmd [[colorscheme molokai]]'
    }

    -- use "folke/neodev.nvim" -- nvim dev config for lua-ls
    -- use 'kassio/neoterm' -- neoterm: access terminal with :T
    use 'scrooloose/nerdtree' -- nerdtree: filesystem explorer
    use { -- nightfox colorshceme
        'EdenEast/nightfox.nvim'
        -- config = 'vim.cmd [[colorscheme carbonfox]]'
    }
    use { -- inject LSP diagnostics, code actions, and more via Lua
        'jose-elias-alvarez/null-ls.nvim',
        run = 'npm i -g eslint_d'
    }
    use 'windwp/nvim-autopairs' -- autopair
    use { -- base16
        'RRethy/nvim-base16',
        -- config = 'vim.cmd [[colorscheme base16-everforest]]'
        -- config = 'vim.cmd [[colorscheme base16-horizon-terminal-dark]]'
        config = 'vim.cmd [[colorscheme base16-oceanicnext]]'
        -- config = 'vim.cmd [[colorscheme base16-paraiso]]'
        -- config = 'vim.cmd [[colorscheme base16-phd]]'
        -- config = 'vim.cmd [[colorscheme base16-seti]]'
        -- config = 'vim.cmd [[colorscheme base16-snazzy]]'
        -- config = 'vim.cmd [[colorscheme base16-solarflare]]'
        -- config = 'vim.cmd [[colorscheme base16-tokyo-city-dark]]'
        -- config = 'vim.cmd [[colorscheme base16-tomorrow-night]]'
        -- config = 'vim.cmd [[colorscheme base16-tomorrow-night-eighties]]'
        -- config = 'vim.cmd [[colorscheme base16-twilight]]'
    }
    use { -- superspeed colorizer
        'norcalli/nvim-colorizer.lua',
        config = function() require('colorizer').setup({'*'}) end
    }
    -- use { -- nvim-dap: debug adapter protocol client
    --  'mfussenegger/nvim-dap',
    --  requires = {
    --    'rcarriga/nvim-dap-ui',
    --    'theHamsta/nvim-dap-virtual-text',
    --  }
    -- }
    use { -- nvim-treesitter
        'nvim-treesitter/nvim-treesitter',
        run = {
            'cargo install tree-sitter-cli', function()
                -- require('nvim-treesitter.install').compilers = { 'clang++'} -- for macOS
                require('nvim-treesitter.install').update {with_sync = true}
            end
        },
        requires = {
            {'nvim-treesitter/nvim-treesitter-context'}, {
                -- nvim tree-sitter autotag
                'windwp/nvim-ts-autotag',
                event = 'InsertEnter'
            }
        }
    }
    use 'nvim-tree/nvim-web-devicons' -- <-> vim-devicons

    use 'nvim-lua/plenary.nvim' -- plenary: a Lua module for asynchronous programming using coroutines

    use { -- colorscheme seti
        'trusktr/seti.vim'
        -- config = 'vim.cmd [[colorscheme seti]]',
    }
    use 'mattn/sonictemplate-vim' -- sonictemplate: quick template with :Template

    use 'preservim/tagbar' -- tagbar
    use { -- telescope
        'nvim-telescope/telescope.nvim',
        tag = '0.1.1',
        requires = {
            {
                -- telescope fzf
                'nvim-telescope/telescope-fzf-native.nvim',
                run = 'make'
            }, {'nvim-telescope/telescope-file-browser.nvim'}
        }
    }
    use 'iberianpig/tig-explorer.vim' -- tig: git client

    -- use 'rstacruz/vim-closer' -- vim-closer
    use 'alvan/vim-closetag' -- vim-closetag: for html tags
    use 'tpope/vim-commentary' -- comment stuff out with gcc/gc
    -- use 'ryanoasis/vim-devicons'  -- <-> nvim-web-devicons
    use 'junegunn/vim-easy-align' -- vim-easy-align: align with ga
    use { -- dispatch compiler plugins (lazy-load)
        'tpope/vim-dispatch',
        opt = true,
        cmd = {'Dispatch', 'Make', 'Focus', 'Start'}
    }
    use 'airblade/vim-gitgutter' -- vim-gitgutter
    use { -- matchup with texts
        'andymass/vim-matchup',
        event = 'VimEnter'
    }
    use 'thinca/vim-quickrun' -- vim-quickrun
    use 'qpkorr/vim-renamer' -- vim-renamer
    -- use 'tpope/vim-sensible' -- vim-sensible: starting point config
    use 'tpope/vim-surround' -- vim-surrond: parentheses, brackets, quotes, XML tags, and more
    use 'bronson/vim-trailing-whitespace' -- vim-trailing-whitespace: mark trailing whitespace
    use { -- vimproc
        'Shougo/vimproc.vim',
        run = 'make'
    }

    use { -- which-key popup
        "folke/which-key.nvim",
        config = function()
            vim.o.timeout = true
            vim.o.timeoutlen = 300
            require("which-key").setup {
                -- your configuration comes here
                -- or leave it empty to use the default settings
                -- refer to the configuration section below
            }
        end
    }
    use 'simeji/winresizer' -- winresizer: can resize windows

    -- use { -- yankring: clipboard history
    --    'vim-scripts/YankRing.vim',
    --    config = function()
    --        vim.g.yankring_history_dir = '$HOME/.cache/nvim'
    --        vim.g.yankring_replace_n_pkey = '<A-p>' -- don't use <C-p>
    --    end
    -- }

    use 'folke/zen-mode.nvim' -- zenmode

    -- Plugins can also depend on rocks from luarocks.org:
    -- use {
    --  'my/supercoolplugin',
    --  rocks = {'lpeg', {'lua-cjson', version = '2.1.0'}}
    -- }
    --
    -- You can specify rocks in isolation
    -- use_rocks 'penlight'
    -- use_rocks {'lua-resty-http', 'lpeg'}
    --
    -- Local plugins can be included
    -- use '~/projects/personal/hover.nvim'
    --
    -- You can specify multiple plugins in a single call
    -- use {'tjdevries/colorbuddy.vim', {'nvim-treesitter/nvim-treesitter', opt = true}}
    --
    -- You can alias plugin names
    -- use {'dracula/vim', as = 'dracula'}

    -- Automatically set up your configuration after cloning packer.nvim
    -- Put this at the end after all plugins
    if packer_bootstrap then require('packer').sync() end
end)
