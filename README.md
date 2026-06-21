![Linux](https://img.shields.io/static/v1?style=for-the-badge&message=Linux&color=222222&logo=Linux&logoColor=FCC624&label=)
![macOS](https://img.shields.io/static/v1?style=for-the-badge&message=macOS&color=000000&logo=macOS&logoColor=FFFFFF&label=)
![Neovim](https://img.shields.io/static/v1?style=for-the-badge&message=Neovim&color=57A143&logo=Neovim&logoColor=FFFFFF&label=)
![Zsh](https://img.shields.io/static/v1?style=for-the-badge&message=Zsh&color=224466&logo=data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmciIHdpZHRoPSI2NzIiIGhlaWdodD0iNjcyIj48c3ZnIHhtbG5zPSJodHRwOi8vd3d3LnczLm9yZyIgd2lkdGg9IjY3MiIgaGVpZ2h0PSI2NjAiIGZpbGw9Im5vbmUiIHZpZXdCb3g9Ijg5IDc2IDY3MiA2NzIiPjxnIHN0cm9rZT0iI2YxNWEyNCIgc3Ryb2tlLWxpbmVjYXA9InJvdW5kIiBzdHJva2UtbGluZWpvaW49InJvdW5kIj48cGF0aCBzdHJva2Utd2lkdGg9IjMyLjE0NyIgZD0iTTQwMyAyMzAgMTA0LjUgNTg1LjUiLz48Y2lyY2xlIGN4PSIxODAuMjE2IiBjeT0iMzA5LjcxNiIgcj0iNjEuNjE0IiBzdHJva2Utd2lkdGg9IjUwLjIwNCIvPjxjaXJjbGUgY3g9IjMyNi4yNjUiIGN5PSI1MDUuOTciIHI9IjYxLjYxNCIgc3Ryb2tlLXdpZHRoPSI1MC4yMDQiLz48cGF0aCBzdHJva2Utd2lkdGg9IjMyLjE0NyIgZD0iTTczOS42NDUgNTc2LjYxSDUyNi40ODYiLz48L2c+PC9zdmc+PHN0eWxlPkBtZWRpYSAocHJlZmVycy1jb2xvci1zY2hlbWU6bGlnaHQpezpyb290e2ZpbHRlcjpub25lfX08L3N0eWxlPjwvc3ZnPg==&logoColor=FFFFFF&label=)

# dotfiles

Personal Linux and macOS dotfiles managed by [chezmoi](https://www.chezmoi.io/).

## Contents

- [Quick Start](#quick-start)
- [Responsibility Split](#responsibility-split)
- [Public Dotfiles Safety](#public-dotfiles-safety)
- [Common Operations](#common-operations)
- [Installation and Package Management](#installation-and-package-management)
- [Zsh](#zsh)
- [Neovim](#neovim)
- [Codex](#codex)
- [Ansible](#ansible)
- [Fonts](#fonts)
- [WakaTime](#wakatime)

## Quick Start

```bash
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply iomz
```

Use `TINY_CHEZMOI=1` for a smaller shell setup.

When `.chezmoi.toml.tmpl` changes, regenerate machine-local chezmoi data before
applying files:

```zsh
chezmoi init
chezmoi apply
```

## Responsibility Split

| Layer | Owns | Source of truth |
|---|---|---|
| apt/brew | OS bootstrap packages, compiler dependencies, and system integration | `run_once_install-packages.sh.tmpl` |
| mise | Pinned development runtimes and developer CLIs, including Bitwarden CLI | `dot_config/mise/config.toml` |
| zinit | Interactive shell tools, portable GitHub release binaries, and zsh integrations | `dot_config/zsh/rc.d/02-plugin-manager.zsh`, `03-tools.zsh` |
| chezmoi | Reproducible dotfiles, templates, and public helper scripts | Managed files in this repository |

Each tool should have one owner. Duplicate installation is reserved for explicit
bootstrap or package-dependency requirements.

In practice:

- apt/brew owns `git`, `gpg`, `gawk`, `mise`, and build dependencies for Python,
  Ruby, and Lua.
- mise owns Python, Node.js, Ruby, Go, Lua, Deno, `pnpm`, Poetry, `just`,
  `direnv`, Neovim, Zellij, and Bitwarden CLI.
- zinit owns interactive tools such as `bat`, `delta`, `fzf`, `ripgrep`, `ghq`,
  `hyperfine`, and `viu`.

Interactive zsh exports `HOMEBREW_FORBIDDEN_FORMULAE` for mise-owned tools.
Homebrew refuses direct installs of listed formula names and packages depending
on them. Versioned or differently named formulae still require review.

## Public Dotfiles Safety

This repository is public. Add files by allowlist, not by whole application
directory.

Allowed:

- reproducible configuration
- public helper scripts
- templates without secrets
- encrypted secret templates

Denied:

- auth files, tokens, and connector credentials
- private keys and machine-local secrets
- sessions, state databases, and history
- logs, caches, and browser data
- generated or vendored content

Use `chezmoi add` for new managed files when possible. Keep repo-only files such
as `README.md`, `LICENSE`, and root `AGENTS.md` ignored by chezmoi.

`.chezmoiignore` contains target paths. Source paths use chezmoi naming, for
example `dot_config/` for `~/.config/`.

## Common Operations

| Change | Edit | Apply or verify |
|---|---|---|
| Add OS dependency | `run_once_install-packages.sh.tmpl` | Review target OS branch; run package manager manually on existing hosts |
| Add or update runtime/CLI | `dot_config/mise/config.toml` | `mise install`, `mise reshim`, then `mise current` |
| Add interactive shell tool | `dot_config/zsh/rc.d/03-tools.zsh` | Start interactive zsh and verify command resolution |
| Change zsh integration | Relevant numbered file under `dot_config/zsh/rc.d/` | `zsh -n <file>`, then start interactive zsh |
| Change managed dotfile | Corresponding chezmoi source path | `chezmoi diff`, then `chezmoi apply` |
| Add managed file | Target file through `chezmoi add` | Inspect source and `chezmoi diff` before commit |

## Installation and Package Management

### System Dependencies

`run_once_install-packages.sh.tmpl` installs bootstrap and system dependencies
during `chezmoi apply`:

- macOS uses Homebrew.
- Debian and Ubuntu use apt.
- Linux installs mise through apt where possible.

### Mise Runtimes and CLIs

Global versions live in `~/.config/mise/config.toml`, managed from
`dot_config/mise/config.toml`.

Install and verify configured tools:

```zsh
mise install
mise reshim
mise doctor
mise current
mise outdated
```

Run `mise reshim` after changing tools so new executables become available.
`run_onchange_after_mise-install.sh.tmpl` also runs installation and reshim when
managed mise configuration changes.

### Bitwarden CLI

Bitwarden CLI is pinned through mise's npm backend. Managed tool name is
`npm:@bitwarden/cli`; executable name is `bw`.

Apply and verify:

```zsh
chezmoi apply ~/.config/mise/config.toml
mise install
mise reshim
mise which bw
bw --version
```

Do not run `mise use bw`; `bw` is not a mise registry tool.

Homebrew's `bitwarden-cli` formula depends on Homebrew Node.js. After
mise-managed `bw` works, remove duplicate formula and check remaining Node.js
dependents:

```zsh
brew uninstall bitwarden-cli
brew uses --installed node
```

Run `brew uninstall node` only when dependency check prints no formulae.

### Neovim Providers

Neovim and provider runtimes are managed by mise.

```zsh
python3 -m pip install --upgrade pip pynvim
gem install neovim
nvim +'checkhealth provider' +qa
```

### Interactive Shell Tools

Zinit manages interactive shell tools and portable GitHub release binaries.
These tools stay outside apt/brew unless bootstrap or OS integration requires
them.

## Zsh

### Startup Order

`~/.zshenv` points zsh at `~/.config/zsh`.

Managed startup order:

```text
$HOME/.zshenv -> $HOME/.config/zsh/.zshrc -> $ZDOTDIR/rc.d/**
```

Default zsh order:

```text
.zshenv -> .zprofile -> .zshrc -> .zlogin -> .zlogout
```

`~/.profile` contains local options such as `TINY_CHEZMOI` and is loaded only
when zsh runs in sh compatibility mode. `TINY_CHEZMOI=1` skips heavy setup.

### rc.d Layout

Files load numerically:

- `00-env.zsh`: environment values not set in `.zshenv`
- `01-options.zsh`: shell options and history
- `02-plugin-manager.zsh`: zinit bootstrap and plugins
- `03-tools.zsh`: zinit-managed binary tools
- `04-mise.zsh`: mise activation
- `05-zeno.zsh`: zeno configuration
- `06-widgets.zsh`: ZLE widgets
- `07-style.zsh`: colors, completion styles, and prompt colors
- `08-hooks.zsh`: shell hooks
- `10-bindkeys.zsh`: key bindings
- `20-aliases.zsh`: aliases and command shortcuts
- `21-dirs.zsh`: named directories

### Startup Profiling

Set `ZPROF` before starting zsh to enable `zprof`. Set `ENABLE_ZPROFTIME` to
write trace logs under `/tmp/zproftime.XXXX`.

```console
zproftime-sort /tmp/zproftime.* | head
```

See [How to profile your zsh startup time](https://esham.io/2018/02/zsh-profiling).

### Zinit Completion Links

After `zinit update`, inspect and clean broken completion links:

```zsh
zinit completions
zinit cclean
```

## Neovim

Configuration lives in `~/.config/nvim`:

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
modules, and OS-specific modules. Plugin specs live in
`lua/iomz/plugins.lua`.

Runtime plugin configuration remains under `after/plugin/` and `plugin/` to
preserve Neovim load semantics.

## Codex

Managed Codex files are intentionally narrow.

Tracked:

- `~/.codex/AGENTS.md`
- inspected personal skills under `~/.codex/skills/<name>/`

Not tracked:

- `~/.codex/config.toml`, auth files, and hooks
- sessions, history, caches, and state databases
- `~/.codex/skills/.system/`

### Skill Ownership

| Category | Location | Owner | Chezmoi policy |
|---|---|---|---|
| Personal and public-safe | `~/.codex/skills/<name>/` | chezmoi | Track only after inspecting every file |
| Private or machine-local | `~/.codex/skills/.local/<name>/` | local machine | Always ignored |
| Codex system skills | `~/.codex/skills/.system/` | Codex | Always ignored |
| Generated skill cache | `~/.codex/skills/.cache/` | Codex or skill tooling | Always ignored |
| Nested metadata and dependencies | `.git/`, `node_modules/` below a skill | upstream tooling | Always ignored |

Keep independently reusable public skills in their own repositories. Chezmoi
manages only intentionally selected personal skills, not installer output,
cloned repository metadata, or dependencies.

Caveman mode is installed through Codex hooks, not through `AGENTS.md`.
`~/.codex/hooks.json` runs caveman activation at session start.

Local `~/.codex/config.toml` should include:

```toml
[features]
codex_git_commit = true

[git]
commit_attribution = "Co-authored-by: Codex <noreply@openai.com>"
```

## Ansible

pipx manages Ansible as an isolated Python CLI application.

```zsh
pipx install --include-deps ansible
pipx upgrade --include-injected ansible
```

## Fonts

On macOS, `run_once_install-meslo-nerd-fonts.sh.tmpl` installs MesloLGS NF into
user font directory during first `chezmoi apply`. Terminal font selection stays
manual.

## WakaTime

WakaTime is not managed by chezmoi. Its API key is machine-local, and
`chezmoi apply` should not require password-manager access.

Configure WakaTime manually where needed:

```zsh
wakatime --api-key
```
