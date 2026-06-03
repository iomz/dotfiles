# Zsh

## Startup Order

This setup uses `~/.zshenv` to point zsh at `~/.config/zsh`.

Managed startup order:

```text
$HOME/.zshenv -> $HOME/.config/zsh/.zshrc -> $ZDOTDIR/rc.d/**
```

Default zsh order:

```text
.zshenv -> .zprofile -> .zshrc -> .zlogin -> .zlogout
```

`~/.profile` contains local options such as `TINY_CHEZMOI`. `~/.profile` is
only loaded when running zsh in sh compatibility mode. When `TINY_CHEZMOI=1`,
heavy setup such as Neovim, cargo, and Deno is skipped.

## rc.d Layout

Files in `rc.d` are loaded numerically:

- `00-env.zsh`: environment values not set in `.zshenv`
- `01-options.zsh`: shell options and history
- `02-plugin-manager.zsh`: Zinit bootstrap and plugins
- `03-tools.zsh`: Zinit-managed binary tools
- `04-asdf.zsh`: asdf setup and completions
- `06-widgets.zsh`: ZLE widgets
- `07-style.zsh`: colors, completion styles, prompt colors
- `10-bindkeys.zsh`: key bindings
- `20-aliases.zsh`: aliases and command shortcuts
- `21-dirs.zsh`: named directories

## Diagnosing Slow Startup

Set `ZPROF` before starting zsh to enable `zprof`.

Set `ENABLE_ZPROFTIME` before starting zsh to write trace logs to
`/tmp/zproftime.XXXX`.

```console
zproftime-sort /tmp/zproftime.* | head
```

Reference:
[How to profile your zsh startup time by Benjamin Esham](https://esham.io/2018/02/zsh-profiling)

## Zinit Completion Links

After `zinit update`, some completions may break. Check with:

```zsh
zinit completions
```

Clean broken links:

```zsh
zinit cclean
```

## Neovim Nightly

The Neovim binary is installed by Zinit. The `nightly` tag does not always move
for new commits. To force reinstall, remove the plugin directory and reopen zsh:

```zsh
rm -fr ${XDG_DATA_HOME}/zinit/plugins/neovim---neovim
```
