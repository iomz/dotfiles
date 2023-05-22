--
-- plugins for lazy.vim
--
return {
    -- bclose: for tig-explorer
    'rbgrouleff/bclose.vim',
    -- snazzy buffer line
    { 'akinsho/bufferline.nvim', dependencies = { 'nvim-tree/nvim-web-devicons' } },
    -- comfortable-motion: smooth scroll
    -- 'yuttie/comfortable-motion.vim',
    -- smart comment
    {
        'numToStr/Comment.nvim',
        config = function() require('Comment').setup() end,
        dependencies = { 'JoosepAlviste/nvim-ts-context-commentstring' }
    },
    -- coplilot
    -- 'github/copilot.vim',
    -- coq_nvim: another coc
    {
        'ms-jpq/coq_nvim',
        branch = 'coq',
        build = function()
            vim.cmd [[:COQdeps]]
        end,
        dependencies = { 'neovim/nvim-lspconfig' }
    },
    -- 9000+ Snippets
    { 'ms-jpq/coq.artifacts',    branch = 'artifacts' },
    -- lua & third party sources -- See https://github.com/ms-jpq/coq.thirdparty
    {
        'ms-jpq/coq.thirdparty',
        branch = '3p',
        config = function() require('coq_3p') end
    },
    -- turn browsers into nvim clients
    { 'glacambre/firenvim', build = function() vim.fn['firenvim#install'](0) end },
    -- git-signs: show git diff
    {
        'lewis6991/gitsigns.nvim',
        dependencies = { 'nvim-lua/plenary.nvim' },
        config = function() require('gitsigns').setup() end
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
            'neovim/nvim-lspconfig',            -- nvim-lspconfig
            'williamboman/mason-lspconfig.nvim' -- mason-lspconfig
        }
    },                                          --
    -- minimap
    { 'wfxr/minimap.vim',   build = 'cargo install --locked code-minimap' },
    -- molokai colorscheme
    {
        'tomasr/molokai'
        -- config = function() vim.cmd [[colorscheme molokai]] end
    },
    -- nvim dev config for lua-ls
    -- 'folke/neodev.nvim',
    -- neoterm: access terminal with :T
    -- 'kassio/neoterm',
    -- nerdtree: filesystem explorer
    'scrooloose/nerdtree',
    -- nightfox colorshceme
    {
        'EdenEast/nightfox.nvim'
        -- config = function() vim.cmd [[colorscheme carbonfox]] end
    },
    -- inject LSP diagnostics, code actions, and more via Lua
    { 'jose-elias-alvarez/null-ls.nvim', build = 'npm i -g eslint_d' },
    -- autopair
    'windwp/nvim-autopairs',
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
    { 'windwp/nvim-ts-autotag',          event = 'InsertEnter' },
    -- <-> vim-devicons
    { 'nvim-tree/nvim-web-devicons' },
    -- plenary: a Lua module for asynchronous programming using coroutines
    'nvim-lua/plenary.nvim',
    -- sonictemplate: quick template with :Template
    'mattn/sonictemplate-vim',
    -- tagbar
    'preservim/tagbar',
    -- telescope
    {
        'nvim-telescope/telescope.nvim',
        tag = '0.1.1',
        dependencies = {
            -- telescope fzf
            { 'nvim-telescope/telescope-fzf-native.nvim', build = 'make' },
            'nvim-telescope/telescope-file-browser.nvim',
            'nvim-lua/plenary.nvim'
        }
    },
    -- tig: git client
    'iberianpig/tig-explorer.vim',
    -- transparent
    'xiyaowong/transparent.nvim',
    -- vim-closer
    -- 'rstacruz/vim-closer',
    -- vim-closetag: for html tags
    'alvan/vim-closetag',
    -- comment stuff out with gcc/gc
    'tpope/vim-commentary',
    -- <-> nvim-web-devicons
    -- 'ryanoasis/vim-devicons',
    -- vim-easy-align: align with ga
    'junegunn/vim-easy-align',
    -- dispatch compiler plugins
    { 'tpope/vim-dispatch',    cmd = { 'Dispatch', 'Make', 'Focus', 'Start' } },
    -- vim-gitgutter
    { 'airblade/vim-gitgutter' },
    -- matchup with texts
    { 'andymass/vim-matchup',  event = 'VimEnter' },
    -- vim-quickrun
    'thinca/vim-quickrun',
    -- vim-renamer
    'qpkorr/vim-renamer',
    -- vim-sensible: starting point config
    -- 'tpope/vim-sensible',
    -- vim-surrond: parentheses, brackets, quotes, XML tags, and more
    'tpope/vim-surround',
    -- vim-trailing-whitespace: mark trailing whitespace
    'bronson/vim-trailing-whitespace',
    -- vimproc
    { 'Shougo/vimproc.vim', build = 'make' },
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
