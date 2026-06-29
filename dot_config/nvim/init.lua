-- =============================================================
--             _       _ _     _
--            (_)_ __ (_) |_  | |_   _  __ _
--            | | '_ \| | __| | | | | |/ _` |
--            | | | | | | |_ _| | |_| | (_| |
--            |_|_| |_|_|\__(_)_|\__,_|\__,_|
-- =============================================================
-- Initialization
vim.cmd("autocmd!")
vim.g.loaded_perl_provider = 0
vim.g.mapleader = ' '       -- Remap space as leader key
vim.g.python3_host_prog = vim.fn.expand("~/.local/share/mise/shims/python3")
vim.g.ruby_host_prog = vim.fn.expand("~/.local/share/mise/shims/ruby")
vim.opt.termguicolors = true
vim.scriptencoding = 'utf-8'
vim.wo.number = true

-- base16 color
local current_theme_name = os.getenv('BASE16_THEME')
if current_theme_name and vim.g.colors_name ~= 'base16-' .. current_theme_name then
    vim.cmd('let base16colorspace=256')
    vim.cmd('colorscheme base16-' .. current_theme_name)
end
local set_theme_path = "$HOME/.config/tinted-theming/set_theme.lua"
local is_set_theme_file_readable = vim.fn.filereadable(vim.fn.expand(
        set_theme_path)) == 1 and
    true or false
if is_set_theme_file_readable then
    vim.cmd("let base16colorspace=256")
    vim.cmd("source " .. set_theme_path)
end

-- Use OSC 52 clipboard when running over SSH.
if vim.env.SSH_TTY or vim.env.SSH_CONNECTION then
  vim.g.clipboard = {
    name = "OSC 52",
    copy = {
      ["+"] = require("vim.ui.clipboard.osc52").copy("+"),
      ["*"] = require("vim.ui.clipboard.osc52").copy("*"),
    },
    paste = {
      ["+"] = require("vim.ui.clipboard.osc52").paste("+"),
      ["*"] = require("vim.ui.clipboard.osc52").paste("*"),
    },
  }

  vim.opt.clipboard = "unnamedplus"
end

-- lazy.vim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
    vim.fn.system({
        "git", "clone", "--filter=blob:none",
        "https://github.com/folke/lazy.nvim.git", "--branch=stable", -- latest stable release
        lazypath
    })
end
vim.opt.rtp:prepend(lazypath)
require('lazy').setup(require('config.plugins'), {
    -- defaults = {lazy = true},
    performance = {
        rtp = {
            disabled_plugins = {
                'gzip', 'matchit', 'netrwPlugin', 'tarPlugin',
                'tohtml', 'tutor', 'zipPlugin'
            }
        }
    }
})

-- Undercurl
-- vim.cmd([[let &t_Cs = "\e[4:3m"]])
-- vim.cmd([[let &t_Ce = "\e[4:0m"]])

-- Turn off paste mode when leaving insert
-- vim.api.nvim_create_autocmd("InsertLeave", {
--  pattern = '*',
--  command = "set nopaste"
-- })

-- Add asterisks in block comments
-- vim.opt.formatoptions:append { 'r' }

require('config.options')
require('config.keymaps')
require('config.commands')

--
-- OS-specific
--
local has = vim.fn.has
local is_mac = has "macunix"
local is_win = has "win32"
local is_wsl = has "wsl"

if is_mac == 1 then require('config.platform.macos') end
if is_win == 1 then require('config.platform.windows') end
if is_wsl == 1 then require('config.platform.wsl') end
