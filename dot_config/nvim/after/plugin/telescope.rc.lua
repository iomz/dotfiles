local status, telescope = pcall(require, "telescope")
if (not status) then return end
local actions = require('telescope.actions')
local builtin = require("telescope.builtin")

local function telescope_buffer_dir() return vim.fn.expand('%:p:h') end

local fb_actions = require("telescope").extensions.file_browser.actions

telescope.setup {
    defaults = {
        prompt_prefix = '  ',
        selection_caret = '❯ ',
        -- sorting_strategy = 'ascending',
        -- layout_config = {
        --  horizontal = {
        --    height = 0.75,
        --    width = 0.8,
        --    prompt_position = 'top',
        --  },
        -- },
        mappings = {
            i = {
                -- actions.which_key shows the mappings for your picker,
                -- e.g. git_{create, delete, ...}_branch for the git_branches picker
                ['<C-h>'] = 'which_key',
                ['<C-j>'] = actions.cycle_history_next,
                ['<C-k>'] = actions.cycle_history_prev,
                ['<C-q>'] = actions.smart_send_to_qflist + actions.open_qflist,
                ['<M-q>'] = actions.send_to_qflist + actions.open_qflist
            },
            n = { ['<C-c>'] = actions.close, ['q'] = actions.close }
        },
        vimgrep_arguments = {
            'rg', '--color=never', '--no-heading', '--with-filename',
            '--line-number', '--column', '--smart-case', '--hidden', '--trim',
            '--glob=!.git/', '--glob=!.zcompcache/', '--glob=!.zcompdump',
            '--glob=!.cache/', '--glob=!.tmp/'
        },
        file_ignore_patterns = {
            '^node_modules/', 'nvim/undo/', '%.git/', '%.mkv', '%.png', '%.jpg',
            '%.jpeg', '%.webp', '%.pdf', '%.mp3', '%.mp4', '%.m4a', '%.opus',
            '%.flac', '%.doc', '%.zip', '%.odt', '%.ots', '%.docx', '%.xlsx',
            '%.xls', '%.pptx', '%.dxvk', '%.rpf', '%.dll', '%.kdbx', '%.exe',
            '%.iso', '%.gif', '%.epub', '%.AppImage', '%.apk', '%.gz'
        }
    },
    pickers = {
        current_buffer_fuzzy_find = { theme = 'ivy' },
        find_files = { hidden = false, no_ignore = false },
        buffers = {
            layout_config = { preview_width = 0.6 },
            ignore_current_buffer = false,
            sort_mru = true,
            mappings = {
                i = { ['<c-d>'] = actions.delete_buffer },
                n = { ['<c-d>'] = actions.delete_buffer }
            }
        }
    },
    extensions = {
        fzf = {
            fuzzy = true,                   -- false will only do exact matching
            override_generic_sorter = true, -- override the generic sorter
            override_file_sorter = true,    -- override the file sorter
            case_mode = 'smart_case'        -- or 'ignore_case' or 'respect_case'
        },
        file_browser = {
            -- dropdown
            theme = 'dropdown',
            -- disables netrw and use telescope-file-browser in its place
            hijack_netrw = true,
            mappings = {
                -- your custom insert mode mappings
                ["i"] = { ["<C-w>"] = function()
                    vim.cmd('normal vbd')
                end },
                ["n"] = {
                    -- your custom normal mode mappings
                    ["N"] = fb_actions.create,
                    ["h"] = fb_actions.goto_parent_dir,
                    ["/"] = function() vim.cmd('startinsert') end
                }
            }
        }
    }
}

---- telescope extensions
-- file_browser
telescope.load_extension("file_browser")

-- keymap
local keymap = vim.keymap.set
local opts = { noremap = true }
keymap('n', '<c-p>', "<cmd>lua require('telescope.builtin').find_files()<CR>", opts)
keymap('n', '<leader>ff', function()
    builtin.find_files({
        cwd = telescope_buffer_dir(),
        hidden = true,
        no_ignore = true,
    })
end, opts)
keymap("n", "<leader>fe", function()
    telescope.extensions.file_browser.file_browser({
        path = "%:p:h",
        cwd = telescope_buffer_dir(),
        respect_gitignore = false,
        hidden = true,
        grouped = true,
        previewer = false,
        initial_mode = "normal",
        layout_config = { height = 40 },
    })
end, opts)
keymap('n', '<leader>fb', "<cmd>lua require('telescope.builtin').buffers()<cr>", opts)
keymap('n', '<leader>fd', "<cmd>lua require('telescope.builtin').diagnostics()<CR>", opts)
keymap('n', '<leader>fg', "<cmd>lua require('telescope.builtin').live_grep()<CR>", opts)
keymap('n', '<leader>fh', "<cmd>lua require('telescope.builtin').help_tags()<CR>", opts)
keymap('n', '<leader>fr', "<cmd>lua require('telescope.builtin').resume()<CR>", opts)

-- fzf
---- FZF syntax:
----    Token   | Match type                  | Description
-------------------------------------------------------------------------------
----    sbtrkt  | fuzzy-match                 | Items that match sbtrkt
----    'wild   | exact-match (quoted)        | Items that include wild
----    ^music  | prefix-exact-match          | Items that start with music
----    .mp2$   | suffix-exact-match          | Items that end with .mp3
----    !fire   | inverse-exact-match         | Items that do not include fire
----    !^music | inverse-prefix-exact-match  | Items that do not start with music
----    !.mp2$  | inverse-suffix-exact-match  | Items that do not end with .mp3
-- telescope.load_extension 'fzf'
-- telescope.load_extension 'projects'
----------------------------------------------------------------------------------
---- Mappings & Which-key
----------------------------------------------------------------------------------
--
-- local builtins = require 'telescope.builtin'
-- local mappings = {
--    ['<leader>'] = {
--        ['<space>'] = { builtins.find_files, 'Find files' },
--        ['f'] = {
--            name = 'Find',
--            ['a'] = { builtins.builtin, 'All builtins' },
--            ['f'] = { builtins.find_files, 'Find files' },
--            ['g'] = { builtins.grep_string, 'Grep string under cursor' },
--            ['w'] = { builtins.live_grep, 'Grep string' },
--            ['h'] = { builtins.help_tags, 'Help tags' },
--            ['c'] = { builtins.commands, 'Commands' },
--            ['r'] = { builtins.oldfiles, 'Recent files' },
--            ['m'] = { builtins.man_pages, 'Man pages' },
--            ['q'] = { builtins.quickfixhistory, 'Quickfix history' },
--            ['p'] = { '<cmd>Telescope projects<CR>', 'Projects' },
--        },
--        ['g'] = {
--            name = 'Git',
--            ['f'] = { builtins.git_files, 'Files' },
--            ['b'] = { builtins.git_branches, 'Branches' },
--            ['c'] = { builtins.git_commits, 'Commits' },
--            ['C'] = { builtins.git_bcommits, 'Buffer commits' },
--            ['m'] = { builtins.git_status, 'Modified files' },
--            ['z'] = { builtins.git_stash, 'Stash' },
--        },
--        ['b'] = {
--            name = 'Buffer',
--            ['b'] = { builtins.buffers, 'Buffers' },
--            ['w'] = { builtins.current_buffer_fuzzy_find, 'Grep string' },
--        },
--        ['l'] = {
--            name = 'LSP',
--        },
--    },
-- }
--
-- require('which-key').register(mappings, { mode = 'n' })
