![Linux](https://img.shields.io/static/v1?style=for-the-badge&message=Linux&color=222222&logo=Linux&logoColor=FCC624&label=)
![macOS](https://img.shields.io/static/v1?style=for-the-badge&message=macOS&color=000000&logo=macOS&logoColor=FFFFFF&label=)
![Neovim](https://img.shields.io/static/v1?style=for-the-badge&message=Neovim&color=57A143&logo=Neovim&logoColor=FFFFFF&label=)
![Zsh](https://img.shields.io/static/v1?style=for-the-badge&message=Zsh&color=224466&logo=data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmciIHdpZHRoPSI2NzIiIGhlaWdodD0iNjcyIj48c3ZnIHhtbG5zPSJodHRwOi8vd3d3LnczLm9yZyIgd2lkdGg9IjY3MiIgaGVpZ2h0PSI2NjAiIGZpbGw9Im5vbmUiIHZpZXdCb3g9Ijg5IDc2IDY3MiA2NzIiPjxnIHN0cm9rZT0iI2YxNWEyNCIgc3Ryb2tlLWxpbmVjYXA9InJvdW5kIiBzdHJva2UtbGluZWpvaW49InJvdW5kIj48cGF0aCBzdHJva2Utd2lkdGg9IjMyLjE0NyIgZD0iTTQwMyAyMzAgMTA0LjUgNTg1LjUiLz48Y2lyY2xlIGN4PSIxODAuMjE2IiBjeT0iMzA5LjcxNiIgcj0iNjEuNjE0IiBzdHJva2Utd2lkdGg9IjUwLjIwNCIvPjxjaXJjbGUgY3g9IjMyNi4yNjUiIGN5PSI1MDUuOTciIHI9IjYxLjYxNCIgc3Ryb2tlLXdpZHRoPSI1MC4yMDQiLz48cGF0aCBzdHJva2Utd2lkdGg9IjMyLjE0NyIgZD0iTTczOS42NDUgNTc2LjYxSDUyNi40ODYiLz48L2c+PC9zdmc+PHN0eWxlPkBtZWRpYSAocHJlZmVycy1jb2xvci1zY2hlbWU6bGlnaHQpezpyb290e2ZpbHRlcjpub25lfX08L3N0eWxlPjwvc3ZnPg==&logoColor=FFFFFF&label=)

# dotfiles

Personal Linux and macOS dotfiles, plus a minimal Claude Cloud agent environment, managed by [chezmoi](https://www.chezmoi.io/).

## Contents

- [Quick Start](#quick-start)
- [Claude Cloud](#claude-cloud)
- [Responsibility Split](#responsibility-split)
- [Public Dotfiles Safety](#public-dotfiles-safety)
- [Common Operations](#common-operations)
- [Installation and Package Management](#installation-and-package-management)
- [Zsh](#zsh)
- [Neovim](#neovim)
- [Codex](#codex)
- [OpenCode](#opencode)
- [Ansible](#ansible)
- [Fonts](#fonts)
- [WakaTime](#wakatime)

## OpenCode

The `cmux-transparent` CLI theme keeps the main view, sidebar, and command surfaces transparent, with opaque dialogs, a blue-gray input fill, slate borders, red user accents, blue secondary text, and a mint scrollbar.
`opencode-update` applies `~/.local/lib/opencode-patches/transparent-borders.patch` to an isolated source worktree before building.
The patch adds a sidebar divider, uses the theme's border token for tool blocks, marks user prompts with a bold `YOU` label and agent-colored border, and uses the form-field background for the input box.
It also wires the transcript scrollbar to its own token and renders image/file badges with the main text color on the form-field selection background.
Open the command palette with `Ctrl+X`, then `P`; `Ctrl+P`/`Ctrl+N` move up/down in the input box.
`Ctrl+B`/`Ctrl+F` move left/right one character; `Ctrl+K` deletes from the cursor to the end of the line.
Build keeps its red theme accent; Plan has an explicit cyan agent color. Attachment badges use dark orange for readable main-text contrast, including submitted file/skill tags.
Patch SHA-256 is recorded in each build manifest and generation name; changing the patch rebuilds even when the upstream commit is unchanged.
If the patch conflicts with upstream, the update stops without changing the active build.
`opencode-rollback` restores the previous generation, including its patch state.
Restart the TUI after activating a new build.

Run offline updater checks with `python3 -m unittest discover -s tests -p 'test_opencode_borders.py'`.
Use `scripts/opencode-theme-lab.html` for a local dark-terminal color preview with role-specific pickers and attachment contrast checks.
The lab includes the personal palette, a main-text picker, optional badge-text linking, and inline attachment RGB/hex controls that do not open an overlapping native picker.
The lab exports color preferences only; it does not modify OpenCode configuration.

### Sidebar trial bundle

- `opencode-git-plugin@0.3.0`: working-tree files and native diff preview, refreshed every 8 seconds. `Ctrl+X`, then `Shift+G`, focuses the list; arrow keys stage/unstage only in list mode and `c` opens a commit prompt.
- `opencode-dir-tree-tui@1.0.6`: expandable project tree and Git badges, placed last below the other sidebar panels and collapsed on TUI startup by a local wrapper. Click its heading to expand. `/dirtree-sidebar` controls visibility, mouse actions, and ignored paths. Right-click opens a file/folder in its system default application.
- Personal Sidebar Dashboard: context meter, selected agent/model, estimated API cost, session token totals, loaded-transcript activity, running subagents, and location-scoped background shells. It reads OpenCode's cached data; no model calls, telemetry, or extra authentication.
- Usage: Codex plan and 12-cell quota bars immediately below Context window. Blue heading and mint bars, amber below 26% remaining, red below 11% remaining.

Dashboard panels can be disabled individually through `context`, `usage`, `session`, `tokens`, `activity`, and `workers` in its `cli.json` plugin options. Sidebar colors are configurable there too. The dashboard embeds the quota component; do not also load its standalone plugin entry.
The dashboard replaces the stock context section; disabling it should also remove `-opencode.sidebar.context` to restore the stock section.
Third-party code remains in local package caches or ignored `node_modules`; only pinned package references and lock files are tracked here.
After-apply installers restore local quota/tree plugin dependencies when missing or when their pinned lockfiles change, including after the config sweep.
They bootstrap the Node version pinned in the managed mise config and run npm through `mise exec`, avoiding inherited asdf shims even before the full runtime installation finishes.
The custom Usage panel sends its active location with quota RPC requests; quota errors display as unavailable rather than checking indefinitely.
Restart the TUI after plugin changes. No binary rebuild is required.

Run dashboard helper checks with `bun test tests/opencode-sidebar.test.ts`.
Dashboard panels reserve fixed row counts, including startup placeholders; Workers shows counts only, without transient command/title rows or blank detail slots. Quota reset times have dedicated non-wrapping rows so refreshes do not shift neighboring panels.
Renderer checks use the build checkout's runtime: from its `packages/tui` directory, run `OPENCODE_TUI_SOURCE="$PWD" bun test ~/.local/share/chezmoi/tests/opencode-sidebar-render.test.ts` after applying the plugins.

## Quick Start

For macOS/Linux workstations:

```bash
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply iomz
```

Use `TINY_CHEZMOI=1` for a smaller shell setup.

When `.chezmoi.toml.tmpl` changes, regenerate machine-local chezmoi data before applying files:

```zsh
chezmoi init
chezmoi apply
```

## Claude Cloud

`claude-cloud` provisions agent instructions, skills, agents, and hooks without deploying the workstation shell or tooling configuration.

### Claude Cloud Environment setup

Requirements: Linux x86_64, a POSIX shell, Git, curl, Node.js, Python 3.10+ with `venv`/pip, and standard Ubuntu tools including `sha256sum`/tar.
The hosted Ubuntu 24.04 image supplies these tools and includes `~/.local/bin` on PATH.
Allow network access to GitHub release assets, public GitHub repositories, and PyPI.

Paste this into Claude Cloud's **Environment setup field**, before Claude starts:

```sh
set -eu
source="$HOME/.local/share/chezmoi"
if [ ! -d "$source/.git" ]; then
  mkdir -p "$(dirname "$source")"
  git clone --single-branch --branch main https://github.com/iomz/dotfiles.git "$source"
else
  git -C "$source" fetch origin main
  git -C "$source" checkout --detach FETCH_HEAD
fi
sh "$source/scripts/bootstrap-claude-cloud.sh"
```

The script installs chezmoi **2.65.0** from its GitHub release asset, verifies SHA-256 before extraction, and initializes the Cloud variant with `--no-tty --promptDefaults`.
A matching installed binary is reused.

Each setup run refreshes this dedicated checkout from `main` and reapplies the Cloud variant; keep it free of local edits.
Cloud may reuse the provisioned filesystem without rerunning setup; rerun setup or invalidate the environment cache to pick up changes on `main`.
To use another checkout, run `sh /path/to/dotfiles/scripts/bootstrap-claude-cloud.sh` during setup.
For a non-default source path, retain `chezmoi --source /path/to/dotfiles` on later commands.

With the pinned chezmoi already installed, use `CHEZMOI_VARIANT=claude-cloud chezmoi init --apply --no-tty --promptDefaults iomz`.
For an existing checkout, run `CHEZMOI_VARIANT=claude-cloud chezmoi --source "$PWD" init --apply --no-tty --promptDefaults` from its source directory.
The selector is saved in machine-local chezmoi `[data].variant`; later `chezmoi apply` and `chezmoi init` retain it without the environment variable.
The default variant is `workstation`; unknown selectors fail initialization.
Switching back requires `CHEZMOI_VARIANT=workstation chezmoi init`, but switching variants does not remove previously deployed files.
Use a separate Cloud home rather than converting an existing workstation.

### Deployment scope

Chezmoi deploys only:

- `~/.claude/CLAUDE.md`, generated from `.chezmoitemplates/AGENTS.md` for user-global instructions.
- `~/.apm/apm.yml`, containing SHA-pinned public dependencies.
- An after-apply script that installs `apm-cli==0.28.0` in `~/.local/share/claude-cloud/apm` and runs `apm install -g --target agent-skills,claude --https`.

APM deploys `ax`, `find-skills`, `typesafe-ai`, `yomiyasu`, the Caveman skill bundle, three Caveman agents, and command hooks.
It merges hooks into local Claude settings and owns its generated skill directories, cache, and lockfile.
Existing Claude settings must be readable JSON objects; invalid or unusable settings stop APM deployment without replacing the file.
`CLAUDE_CONFIG_DIR`, if set, must resolve to `~/.claude`; redirected APM deployment is rejected.
Cloud excludes private `iomz/skills` dependencies and the vault-only `brain-vault` skill; no GitHub credentials are required.

No workstation shell/editor/mise configuration, Git configuration, credentials, or native plugin registration is deployed.
Cloud has no `/plugin` interface; use the deployed skills, agents, and hooks.
Skill-associated optional tools such as `ax`, `gh`, or `npx` are not installed by this variant; supply them in the Cloud image when needed.

Provision before startup so agents and SessionStart hooks are available from the first prompt.
Installing a SessionStart hook during an active session does not replay the initial event.

Cloud's `.gitconfig` (including signing configuration), `~/.claude.json`, and unrelated `.claude` launcher/session/synced-skill files remain Cloud-owned.
Chezmoi manages only the allowlisted instruction file and manifest, plus its own machine-local configuration/state.
Use repo `.mcp.json` for repo MCP needs; this variant does not manage it.

APM installation runs on first apply and when the Cloud manifest/script changes; failures are retried by the next apply.
For an explicit reinstall without a manifest change:

```sh
(
  set -e
  script=$(mktemp)
  trap 'rm -f "$script"' 0
  chezmoi cat "$HOME/claude-cloud-apm.sh" > "$script"
  sh "$script"
)
```

### Validation

```sh
just test
# Or, without just:
python3 -m unittest discover -s tests -v
```

Tests cover macOS/Linux rendering, Cloud selection and allowlisting, host-state preservation, checksum-verified noninteractive bootstrap, and idempotency with APM stubbed.
They do not require network access.

For real Ubuntu 24.04 x86_64/dash, pinned chezmoi/APM, settings merge/preservation, and idempotency checks:

```sh
just test-integration
# Or, without just:
sh tests/integration/run-claude-cloud.sh
```

This opt-in test requires Docker with Linux amd64 execution/emulation and network access to Ubuntu packages, GitHub releases/repositories, and PyPI.
It runs in a disposable container with the checkout mounted read-only, HOME `/root`, and cwd outside HOME.
Use `chezmoi apply --dry-run` to inspect a selected deployment without running installers.
Hosted-Cloud APM provisioning and first-prompt skill/agent/hook discovery still require validation in the target environment.

### Shared agent instructions

`.chezmoitemplates/AGENTS.md` is the single source for global instructions.
Claude receives a generated `~/.claude/CLAUDE.md` deployment artifact; Codex receives the same text at `~/.codex/AGENTS.md` with its tool-specific appendix.
The repository root `AGENTS.md` contains dotfiles-maintenance rules only and is not deployed.

## Responsibility Split

| Layer    | Owns                                                                                                                                                           | Source of truth                             |
| -------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------- |
| apt/brew | OS bootstrap packages, native build dependencies, GUI-adjacent tools, system integration, and host-managed convenience CLIs                                    | `run_once_install-packages.sh.tmpl`         |
| mise     | Versioned developer environments, reproducible runtimes, runtime-adjacent package managers, and developer CLIs that should not follow the host package manager | `dot_config/mise/config.toml`               |
| zinit    | Zsh plugins, prompt fallback, completion snippets, and shell integrations                                                                                      | `dot_config/zsh/rc.d/02-plugin-manager.zsh` |
| chezmoi  | Reproducible dotfiles, templates, and public helper scripts                                                                                                    | Managed files in this repository            |

Interactive zsh exports `HOMEBREW_FORBIDDEN_FORMULAE` for mise-owned tools. Homebrew refuses direct installs of listed formula names and packages depending on them. Versioned or differently named formulae still require review.

## Public Dotfiles Safety

This repository is public. Add files by allowlist, not by whole application directory.

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

Use `chezmoi add` for new managed files when possible. Keep repo-only files such as `README.md`, `LICENSE`, and root `AGENTS.md` ignored by chezmoi.

`.chezmoiignore` contains target paths. Source paths use chezmoi naming, for example `dot_config/` for `~/.config/`.

## Common Operations

| Change                               | Edit                                                | Apply or verify                                                         |
| ------------------------------------ | --------------------------------------------------- | ----------------------------------------------------------------------- |
| Add OS dependency                    | `run_once_install-packages.sh.tmpl`                 | Review target OS branch; run package manager manually on existing hosts |
| Add or update runtime/CLI            | `dot_config/mise/config.toml`                       | `mise install`, `mise reshim`, then `mise current`                      |
| Add zsh plugin or completion snippet | `dot_config/zsh/rc.d/02-plugin-manager.zsh`         | Start interactive zsh and verify plugin/widget/completion availability  |
| Change zsh integration               | Relevant numbered file under `dot_config/zsh/rc.d/` | `zsh -n <file>`, then start interactive zsh                             |
| Change managed dotfile               | Corresponding chezmoi source path                   | `chezmoi diff`, then `chezmoi apply`                                    |
| Add managed file                     | Target file through `chezmoi add`                   | Inspect source and `chezmoi diff` before commit                         |

## Installation and Package Management

### Pre-installation Cleanup

On the first workstation apply, `run_once_before_00-cleanup-legacy-config.sh.tmpl` moves repo-owned application configuration into a timestamped `~/.chezmoi-backups/pre-install.<UTC timestamp>.<random suffix>` before installing packages or writing managed files.
The backup directory is private (mode `0700`); nothing is deleted or added to Git.
This noninteractive migration also runs once on existing workstations when they first receive the script.

The application allowlist covers:

- Config trees under `~/.config`: `vim`, `nvim`, `zsh`, `git`, `direnv`, `mise`, `rtx`, `ghostty`, `zellij`, `zeno`, `vale`, `yamlfmt`, `tig`, and `opencode`; plus `starship.toml`.
- Home-level config trees: `~/.vim`, `~/.zsh`, and `~/.hammerspoon`.
- Home-level dotfiles: `.vimrc`, `.gvimrc`, `.exrc`, `.gitconfig`, `.profile`, `.inputrc`, `.mostrc`, `.screenrc`, `.tigrc`, `.mise.toml`, `.rtx.toml`, and `.tool-versions`.
- Zsh startup files: `.zshenv`, `.zprofile`, `.zshrc`, `.zlogin`, `.zlogout`, plus their `.zwc` files.

Whole config trees move, including unknown files, so stale plugins, hooks, alternate configs, and modules cannot load alongside the fresh setup.
Standalone history and credential files, runtime installations, data/cache/state directories, unrelated applications, and project-local configs stay untouched.
Claude, Codex, APM, and shared agent deployment directories are excluded; OpenCode's config tree is swept except for its host-owned `service.json`, and its separate auth/session data is not.
Any secrets or history embedded in a swept config tree remain in its private local backup; treat backups as sensitive and never publish them.
Symlinks in the allowlist are moved without modifying their targets; a symlinked `~/.config` or backup root fails deployment without prompting or moving anything.
Claude Cloud skips this migration.

Preview with `chezmoi apply --dry-run` before applying.
The script prints its backup path; restore selected local customizations from there after reviewing them.
After sweeping a running OpenCode installation, wait for active tasks to finish, run `opencode service restart`, then reopen the TUI.
Restarting only the TUI can leave the background service with stale per-location plugin state and an unavailable Usage panel.
The migration does not restart applications or services automatically.
In particular, an existing `~/.zprofile` is backed up, not automatically restored, since managed Zsh explicitly sources it.
Subsequent applies leave new local customizations alone.
`~/.chezmoi-backups/.pre-install-complete` also prevents repeat cleanup if the script changes or chezmoi's script state is reset.
Failed moves stop deployment, retain completed backups, and retry on the next apply; completion is recorded only after all moves succeed.
An intentional new sweep requires removing this completion marker and resetting this script's chezmoi run state.
Inherited config-path overrides such as `XDG_CONFIG_HOME` or `ZDOTDIR` and system-level configs are outside this home-scoped migration.

### System Dependencies

For workstations, `run_once_install-packages.sh.tmpl` installs bootstrap and system dependencies during `chezmoi apply`:

- macOS uses Homebrew.
- Debian and Ubuntu use apt.
- Linux installs mise through apt where possible.

### Mise Runtimes and CLIs

Global versions live in `~/.config/mise/config.toml`, managed from `dot_config/mise/config.toml`.

Install and verify configured tools:

```zsh
mise install
mise reshim
mise doctor
mise current
mise outdated
```

Run `mise reshim` after changing tools so new executables become available.
`run_onchange_after_mise-install.sh.tmpl` also runs installation and reshim when managed mise configuration changes.

### Bitwarden CLI

Bitwarden CLI is pinned through mise's npm backend. Managed tool name is `npm:@bitwarden/cli`; executable name is `bw`.

Apply and verify:

```zsh
chezmoi apply ~/.config/mise/config.toml
mise install
mise reshim
mise which bw
bw --version
```

Do not run `mise use bw`; `bw` is not a mise registry tool.

### Neovim Providers

Neovim uses mise shims for Python and Ruby providers.
Python is configured in `dot_config/mise/config.toml`; a Ruby runtime must be available separately for the Ruby provider.
Install provider packages in their corresponding runtimes:

```zsh
python3 -m pip install --upgrade pip pynvim
gem install neovim
nvim +'checkhealth provider' +qa
```

### Interactive Shell Integrations

Zinit manages zsh-specific integrations only. It should not be used as a general binary installer.

Managed by zinit:

- zsh plugins
- zsh completion snippets
- Pure fallback prompt
- zsh-autosuggestions
- fast-syntax-highlighting
- zeno.zsh
- zsh-z and other shell-only helpers

Managed by mise or brew instead:

- standalone CLI binaries
- language runtimes
- GitHub release binaries used outside zsh
- tools that need OS integration

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

On Linux ARM, `.profile` and `.zshenv` enable `TINY_CHEZMOI` by default.
Set `TINY_CHEZMOI=1` to skip heavier interactive integrations.

### rc.d Layout

Files load numerically:

- `00-env.zsh`: environment values not set in `.zshenv`
- `01-options.zsh`: shell options and history
- `02-plugin-manager.zsh`: zinit bootstrap, zsh plugins, and completion snippets
- `03-tools.zsh`: reserved tool-integration slot, currently empty
- `04-mise.zsh`: mise activation
- `05-zeno.zsh`: zeno configuration
- `06-widgets.zsh`: ZLE widgets
- `07-style.zsh`: colors, prompt, ZLE highlighting, pager styling, and optional stderr coloring
- `08-completion.zsh`: completion paths, `compinit`, and completion styles
- `09-hooks.zsh`: shell hooks
- `10-bindkeys.zsh`: key bindings
- `20-aliases.zsh`: aliases and command shortcuts
- `21-dirs.zsh`: named directories

### Startup Profiling

Set `ZPROF` before starting zsh to enable `zprof`. Set `ENABLE_ZPROFTIME` to write trace logs under `/tmp/zproftime.XXXX`.

```console
zproftime-sort /tmp/zproftime.* | head
```

See [How to profile your zsh startup time](https://esham.io/2018/02/zsh-profiling).

### Completion Maintenance

Completion setup is split between zinit snippets, Homebrew-managed completion directories, and local zstyle configuration.

Homebrew completions are discovered through `fpath`, not through zinit snippets.
If `compinit` reports insecure directories, inspect and fix them:

```zsh
compaudit
compaudit | xargs chmod go-w
```

Set `ZSH_TRUST_INSECURE_COMPLETIONS=1` only as a temporary escape hatch.

After zinit snippet updates, inspect and clean completion links when needed:

```zsh
zinit completions
zinit cclean
```

## Neovim

Configuration lives in `~/.config/nvim`:

```text
init.lua
lua/config/
  commands.lua
  keymaps.lua
  options.lua
  platform/
    macos.lua
    windows.lua
    wsl.lua
  plugins.lua
after/plugin/
plugin/
```

`init.lua` handles global startup, theme loading, lazy.nvim bootstrap, base modules, and OS-specific modules. Plugin specs live in `lua/config/plugins.lua`.

Runtime plugin configuration remains under `after/plugin/` and `plugin/` to preserve Neovim load semantics.

## Codex

Managed Codex files are intentionally narrow.

Tracked:

- `~/.codex/AGENTS.md`

Not tracked:

- `~/.codex/config.toml`, auth files, and hooks
- sessions, history, caches, and state databases
- `~/.codex/skills/.system/`

### Skill Ownership

| Category                         | Location                               | Owner                  | Chezmoi policy                         |
| -------------------------------- | -------------------------------------- | ---------------------- | -------------------------------------- |
| Personal and public-safe         | `~/.codex/skills/<name>/`              | chezmoi                | Track only after inspecting every file |
| Private or machine-local         | `~/.codex/skills/.local/<name>/`       | local machine          | Always ignored                         |
| Codex system skills              | `~/.codex/skills/.system/`             | Codex                  | Always ignored                         |
| Generated skill cache            | `~/.codex/skills/.cache/`              | Codex or skill tooling | Always ignored                         |
| Nested metadata and dependencies | `.git/`, `node_modules/` below a skill | upstream tooling       | Always ignored                         |

Keep independently reusable public skills in their own repositories. Chezmoi manages only intentionally selected personal skills, not installer output, cloned repository metadata, or dependencies.

### Shared Agent Skills

`~/.agents/skills` is a cross-client deployment surface, not a directory for chezmoi to mirror wholesale.
Its contents can come from personal source files, upstream installers, or skill package managers, so ownership must remain explicit.

| Category | Owner | Chezmoi policy |
| --- | --- | --- |
| Personally authored, public-safe skill | chezmoi or its own repository | Track only through a per-skill allowlist |
| Third-party skill | APM or upstream installer | Track a declarative manifest with pinned SHAs, not deployed files or lockfiles |
| `.skill-lock.json` and similar installer state | installer | Never track as hand-authored configuration |
| Caches, cloned metadata, and dependencies | package manager | Never track |

APM deploys to `~/.agents/skills` and `~/.claude/skills` (`agent-skills` and `claude` targets in `apm.yml`).
It also owns Caveman: its skills, agents, and hooks land in `~/.claude`, and APM edits `~/.claude/settings.json`.
APM manages third-party skills such as `ax`, `find-skills`, and `typesafe-ai` from pinned upstream commits.
`iomz/skills` supplies selected personal skills through the same deployment path.
The vault-specific `brain-vault` skill is owned by `iomz/brain-vault` (`Skills/Common/brain-vault`) and deployed the same way.
Workstation installs require GitHub read access to private `iomz/skills`; Cloud installs use public dependencies only.
Keep skill names unique across `~/.agents/skills` and `~/.codex/skills` to avoid duplicate discovery.
Do not infer skill ownership from a same-named binary installer; verify skill provenance separately before updates.

The APM manifest lives at `~/.apm/apm.yml`, rendered from `dot_apm/apm.yml.tmpl`; chezmoi owns this inspected declarative input, and the commit SHA pins in it are the source of truth.
`~/.apm/apm.lock.yaml` is generated per machine and not tracked; install with `apm install -g`, not `--frozen`.
Do not let chezmoi and APM own the same deployed skill directory.

#### Updating APM-managed skills

Updates are manual and review-driven; no scheduled job updates skills in the background.
Start with this read-only inventory:

```sh
apm outdated -g
```

An `outdated` result means APM found a newer annotated upstream tag.
It does not prove the selected skill changed; compare the pinned and proposed skill subpaths before advancing the pin.
An `unknown` result means APM could not establish a newer version for that commit-pinned dependency; it does not prove the dependency is current.

Do not use `apm update -g --yes` as a blanket routine.
Dependencies are deliberately pinned to commit SHAs, and APM will not replace a revision pin with a branch or lightweight tag.
Inspect the authoritative upstream diff, release notes, skill contents, license, and provenance before changing only the intended pin in the chezmoi-managed manifest.

```sh
chezmoi edit ~/.apm/apm.yml
chezmoi apply ~/.apm/apm.yml
apm install -g
chezmoi diff ~/.apm/apm.yml
git diff --check
git diff -- dot_apm/apm.yml.tmpl
```

Verify changed skill frontmatter and any associated CLI before committing.
Keep generated skill directories under `~/.agents/skills` out of chezmoi, and never commit or push update changes automatically.

Caveman activation for Codex requires a local `~/.codex/hooks.json` SessionStart hook.
Codex hooks are not managed by chezmoi.

Local `~/.codex/config.toml` should include:

```toml
[features]
codex_git_commit = true

[git]
commit_attribution = "Co-authored-by: Codex <noreply@openai.com>"
```

## Ansible

Mise manages Ansible through its pipx backend as an isolated Python CLI application.

```zsh
mise install pipx:ansible
mise which ansible
```

## Fonts

On macOS, `run_once_install-meslo-nerd-fonts.sh.tmpl` installs MesloLGS NF into user font directory during first `chezmoi apply`. Terminal font selection stays manual.

## WakaTime

WakaTime is not managed by chezmoi. Its API key is machine-local, and `chezmoi apply` should not require password-manager access.

Configure WakaTime manually where needed:

```zsh
wakatime --api-key
```
