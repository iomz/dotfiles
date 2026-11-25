# Zsh

[Back to the README](../README.md)

## Startup order

`~/.zshenv` sets `ZDOTDIR` to `~/.config/zsh`, so zsh reads:

```text
~/.zshenv -> $ZDOTDIR/.zshrc -> $ZDOTDIR/rc.d/* -> ~/.zprofile -> $ZDOTDIR/.zlogin (login shells)
```

- zsh itself never reads `~/.zprofile`: the managed `.zshrc` sources it last, so it is the place for host-local customization.
- `.zshenv` also exports `LANG` and `LC_ALL` as `en_US.UTF-8` for every zsh, and drops `LANGUAGE`.
- `.zlogin` recompiles the startup files in the background.
  Each file gets its own `.zwc`, written under a temporary name and renamed into place.

## Tiers

| | stem | leaf |
| --- | --- | --- |
| options, history, completion, key bindings, aliases | ✓ | ✓ |
| prompt | Starship, else Pure | colored, with the host in its Starship color |
| zinit plugins, zeno, mise activation | ✓ | – |
| `Ctrl+R` history search | zeno | fzf, else pattern search |

On helm hosts whose login shell is not zsh, an apply runs `chsh -s` with `/bin/zsh` or `/usr/bin/zsh`, never a mise or Homebrew zsh whose path can change.
Without an interactive terminal it only prints the command.
On Linux, the apply also creates `~/.profile` when missing, so bash logins still read `~/.bashrc`.

## rc.d

`rc.d` and `functions` are exact directories: an apply deletes unmanaged files in them.
Files load in numeric order:

| File | Holds |
| --- | --- |
| `00-env.zsh` | environment not set in `.zshenv`, Homebrew paths |
| `00-homebrew-guard.zsh` | `HOMEBREW_FORBIDDEN_FORMULAE` (stem) |
| `01-options.zsh` | shell options and history |
| `02-plugin-manager.zsh` | zinit, plugins and completion snippets (stem) |
| `03-tools.zsh` | reserved, empty |
| `04-mise.zsh` | mise activation (stem) |
| `05-zeno.zsh` | zeno (stem) |
| `06-widgets.zsh` | ZLE widgets |
| `07-style.zsh` | colors, prompt, highlighting, pager styling |
| `08-completion.zsh` | `fpath`, `compinit`, completion styles |
| `09-hooks.zsh` | shell hooks |
| `10-bindkeys.zsh` | key bindings |
| `20-aliases.zsh` | aliases |
| `21-dirs.zsh` | named directories |

zinit manages zsh plugins, completion snippets, the Pure fallback prompt, zsh-autosuggestions, fast-syntax-highlighting, zeno and zsh-z.
Standalone binaries and runtimes come from mise or the OS package manager instead, never from zinit.

## Prompt latency

Starship scans directories for at most 10 ms, runs commands for at most 100 ms, and does not follow symlinks.
Slow optional modules may then be missing; run `starship timings` in a slow directory and disable the module rather than raising the timeouts.

## Profiling

Set `ZPROF` before starting zsh to enable `zprof`.
Set `ENABLE_ZPROFTIME` to write traces under `/tmp/zproftime.XXXX`, then:

```sh
zproftime-sort /tmp/zproftime.* | head
```

See [How to profile your zsh startup time](https://esham.io/2018/02/zsh-profiling).

## Completion

Homebrew completions come through `fpath`, not zinit.
If `compinit` reports insecure directories:

```zsh
compaudit
compaudit | xargs chmod go-w
```

`ZSH_TRUST_INSECURE_COMPLETIONS=1` is a temporary escape hatch only.
After zinit snippet updates, clean stale completion links with `zinit completions` and `zinit cclean`.
