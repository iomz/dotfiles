# Neovim

Configuration lives in `~/.config/nvim`.

Layout:

```text
init.lua
lua/iomz/
  commands.lua
  keymaps.lua
  options.lua
  os/
    macos.lua
    windows.lua
    wsl.lua
  plugins.lua
after/plugin/
plugin/
```

`init.lua` handles global startup, theme loading, lazy.nvim bootstrap, base
modules, and OS-specific modules.

Plugin specs live in `lua/iomz/plugins.lua`.

Runtime plugin config remains under `after/plugin/` and `plugin/` for now.
Those files are intentionally left in Neovim runtime paths to avoid changing
load semantics during this refactor.
