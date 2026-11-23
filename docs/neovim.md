# Neovim and Vim

[Back to the README](../README.md)

## Which editor

| | stem | leaf |
| --- | --- | --- |
| Neovim and `~/.config/nvim` | ✓ | – |
| plugin-free `~/.vimrc`, also fine for `vim-tiny` | ✓ | ✓ |
| `vim` from apt on Linux | ✓ | ✓ |

zsh sets `EDITOR` and `VISUAL` to the first of `nvim`, `vim`, `vim.tiny` and `vi`.
`SUDO_EDITOR` is its absolute path, plus `-i NONE` for Neovim and Vim, so root-only file contents never reach shada or viminfo.
Neither keeps undo or backup files for temporary directories, where `sudoedit` puts its copies.

## Layout

```text
~/.config/nvim/
  init.lua            startup, theme, lazy.nvim bootstrap, OS modules
  lua/config/
    commands.lua
    keymaps.lua
    options.lua
    plugins.lua       plugin specs
    platform/         macos.lua, windows.lua, wsl.lua
  after/plugin/       runtime plugin configuration
  plugin/
```

Runtime plugin configuration stays under `after/plugin/` and `plugin/` to keep Neovim's load order.

## Plugins

When the managed config changes, an apply runs `Lazy! sync` once (`run_onchange_after_nvim-plugin-sync.sh.tmpl`).
Plugin commits are not pinned across hosts.
The sync is best effort: a failed update does not fail the apply, so check its output and rerun `:Lazy sync`.

The remote plugin providers for Node, Perl, Python and Ruby are off, since no plugin uses them, so runtime upgrades need no `pynvim` or `neovim` packages.
