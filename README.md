![Linux](https://img.shields.io/static/v1?style=for-the-badge&message=Linux&color=222222&logo=Linux&logoColor=FCC624&label=)
![macOS](https://img.shields.io/static/v1?style=for-the-badge&message=macOS&color=000000&logo=macOS&logoColor=FFFFFF&label=)
![Neovim](https://img.shields.io/static/v1?style=for-the-badge&message=Neovim&color=57A143&logo=Neovim&logoColor=FFFFFF&label=)
![Zsh](https://img.shields.io/static/v1?style=for-the-badge&message=Zsh&color=224466&logo=zsh&logoColor=F15A24&label=)

# dotfiles

Personal dotfiles for Linux and macOS hosts, plus a minimal agent sandbox, managed by [chezmoi](https://www.chezmoi.io/).
One tool inventory decides what each host gets, so a laptop, a home server and a tiny appliance share one source.

- [Hosts](#hosts)
- [Quick start](#quick-start)
- [Everyday commands](#everyday-commands)
- [Tools and packages](#tools-and-packages)
- [Agents and skills](#agents-and-skills)
- [Agent sandbox](#agent-sandbox)
- [First apply on an existing host](#first-apply-on-an-existing-host)
- [Slimming a former stem host](#slimming-a-former-stem-host)
- [Public repository rules](#public-repository-rules)
- [Testing](#testing)
- [More](#more)

## Hosts

Every host has a **variant** and, on helm hosts, a **tier**.

| Variant | What it is | Gets |
| --- | --- | --- |
| `helm` (default) | a machine you operate | shell, editor, tools and agent setup, by tier |
| `agent-sandbox` | a disposable agent workspace, such as Claude Cloud | agent instructions and public skills only |

| Tier | Hosts | Gets |
| --- | --- | --- |
| **stem** | in the `stem` group of `.chezmoidata/tools.toml` | everything: mise runtimes, Neovim, zsh plugins, personal skills |
| **leaf** | every other host, declared or not | base and ops packages, slim zsh, plain vim |

The variant is chosen once at `chezmoi init` (`CHEZMOI_VARIANT`) and stored in the local chezmoi config.
The old names `workstation` and `claude-cloud` keep working until the next `chezmoi init` rewrites them.

## Quick start

Any helm host:

```sh
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply iomz
```

The prompt asks for the host name, which picks the tier.
The apply installs packages, and on a host whose login shell is not zsh it runs `chsh`; both may ask for your password.

On a fresh Mac, set the host name, then run the install with chezmoi's built-in Git:

```sh
sudo scutil --set HostName <host>
cd ~ && sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply --use-builtin-git true iomz
```

- Do not install Homebrew or the Xcode Command Line Tools first: `/usr/bin/git` only offers to install the tools, and the apply runs the Homebrew installer, which adds them.
- The full Xcode from the App Store is independent; install it whenever a project needs it.
- chezmoi lives in `~/bin` on every host, macOS included, and updates itself with `chezmoi upgrade`; Homebrew must not install it.

A new stem host then needs one GitHub login, the only credential private sources use:

```sh
cd ~/.local/share/chezmoi
gh auth login
just apm-install
just skills-pull && chezmoi apply
```

When `.chezmoi.toml.tmpl` changes, chezmoi warns on the next apply; regenerate the local config first:

```sh
chezmoi init
chezmoi apply
```

## Everyday commands

Run `just` recipes from `~/.local/share/chezmoi`.

| Command | Does |
| --- | --- |
| `chezmoi update` | pull this repository and apply it |
| `just tool-add <name> <manager>` | add a tool to the inventory, then apply |
| `just tool-bump [name]` | update pinned mise versions, then apply |
| `just tool-move <name> mise\|brew` | move a macOS tool between mise and Homebrew |
| `just tool-check` | validate the inventory and preview the diff |
| `just skills-pull` | clone or fast-forward personal skills |
| `just apm-install` | install the pinned third-party skills and plugins |
| `just test` | run the unit tests |

## Tools and packages

### Who owns what

| Layer | Owns | Declared in |
| --- | --- | --- |
| apt / Homebrew | OS packages, ops tools, macOS apps | `.chezmoidata/tools.toml` |
| mise | versioned runtimes and developer CLIs, on stem hosts | `.chezmoidata/tools.toml` |
| zinit | zsh plugins and completion snippets, on stem hosts | `dot_config/zsh/exact_rc.d/02-plugin-manager.zsh.tmpl` |
| chezmoi | dotfiles, templates and helper scripts | this repository |

### The inventory

`.chezmoidata/tools.toml` declares each tool once; its header describes the format.

- A tool uses either `mise = "<version>"` or OS keys: `darwin.brew`, `darwin.cask` (macOS apps), `linux.apt`, `linux.brew`.
- `hosts = [...]` or `groups = [...]` limits it; neither means every host. mise entries must declare one.
- `arch`, `hold` and `bin` are optional filters and hints.
- `~/.config/mise/config.toml` is rendered from it: edit the inventory, not the rendered file, and never `mise use`.

Edit with the `just tool-*` recipes; each validates the result and reverts an invalid edit.
`tool-add` and `tool-bump` apply afterwards (skip with `--no-apply`); committing stays manual.

### What an apply installs

`run_once_install-packages.sh.tmpl` installs what is missing and never upgrades or removes anything.

- **Linux:** apt when root is available (running as root, `sudo -n`, or a sudo password prompt on a terminal), else Homebrew, else it skips and prints how to retry.
- **macOS:** Homebrew formulae, then apps one by one, so a password prompt or a failed app does not stop the rest.
  Without Homebrew, `run_before_10-install-homebrew.sh.tmpl` runs its official installer first; it needs an administrator account and a terminal.
- **Unknown names**, such as a package missing from an older release, are skipped and reported instead of failing the install.
- **mise** comes from apt on Linux and Homebrew on macOS, only on stem hosts; `run_onchange_after_mise-install.sh.tmpl` runs `mise install` when the config changes.
- **Locale:** Linux generates `en_US.UTF-8` and makes it the system default; zsh exports it as `LANG` and `LC_ALL` everywhere.
- **Login shell:** on helm hosts whose login shell is not zsh, an apply runs `chsh -s` with `/bin/zsh` or `/usr/bin/zsh`.

Mac App Store apps (LINE, Kindle) and unnotarized apps stay manual.
Removing a tool from the inventory does not uninstall it.

Interactive zsh exports `HOMEBREW_FORBIDDEN_FORMULAE`, so Homebrew refuses formulae that mise owns, plus Homebrew's `zsh`.

## Agents and skills

### Instructions

`.chezmoitemplates/AGENTS.md` is the single source of global agent instructions.
It renders to `~/.claude/CLAUDE.md`, and to `~/.codex/AGENTS.md` with a Codex appendix.
The repository's own `AGENTS.md` holds maintenance rules for this repository and is not deployed.

### Claude Code status line

`~/.local/bin/claude-code-status-line` holds the layout: segments, gap and the Caveman badge.
On stem hosts a run script points `statusLine` in `~/.claude/settings.json` at it and changes no other key, since APM and Claude Code own that file.
To change the layout, edit the wrapper here; `SL_*` variables set in the `statusLine` command still override it on one host.

### Who owns which skills

| Skills | Source | Deployed by |
| --- | --- | --- |
| personal | private [`iomz/skills`](https://github.com/iomz/skills), cloned to `~/.local/share/agent-skills` | chezmoi links, one per skill, in `~/.claude/skills` |
| third-party (`ax`, `find-skills`, `typesafe-ai`) and `brain-vault` | upstream repositories, pinned by commit in `dot_apm/apm.yml.tmpl` | APM, into `~/.agents/skills` and `~/.claude/skills` |
| Caveman and `yomiyasu` | upstream, pinned the same way | APM, as native Claude Code plugins under `~/.agents/plugins` |

chezmoi never tracks skill contents, APM output or its lockfile.
OpenCode reads both `~/.agents/skills` and `~/.claude/skills` and prefers the `~/.agents` copy, so keep names unique across the two.

### Personal skills

A merge to `iomz/skills` `main` followed by `just skills-pull` is a release.
The recipe clones over HTTPS with the `gh` login, later fast-forwards `main`, and stops on local changes, another branch or diverged commits; it never resets, stashes or forces.

- Edit skills in a separate checkout, never in the live clone.
- To add a skill, add `private_dot_claude/skills/symlink_<name>.tmpl` once it is on `iomz/skills` `main`.
- An apply stops if a directory stands where a link goes, since chezmoi would replace it, and warns about same-named copies in `~/.agents/skills`.

### Third-party skills and plugins

`just apm-install` runs `apm install -g` with the `gh` token, which private `iomz/brain-vault` needs.
Updates are manual and reviewed:

1. `apm outdated -g` lists candidates; "outdated" and "unknown" do not prove a skill changed.
2. Read the upstream diff, especially hook code, which runs on every session.
3. Change only that pin with `chezmoi edit ~/.apm/apm.yml`, then `chezmoi apply ~/.apm/apm.yml` and `just apm-install`.
4. Ask a new Claude Code session whether Caveman is active, then commit.

Never run `apm update -g --yes` as a routine.
Older APM releases cannot deploy Caveman's plugin hooks; bump APM with `just tool-bump apm-cli` first when needed.

### Codex

Only `~/.codex/AGENTS.md` is tracked; `config.toml`, auth, hooks, sessions and `~/.codex/skills/.system/` stay local.
Caveman for Codex needs a local `~/.codex/hooks.json` SessionStart hook, and the local `config.toml` should include:

```toml
[features]
codex_git_commit = true

[git]
commit_attribution = "Co-authored-by: Codex <noreply@openai.com>"
```

## Agent sandbox

The `agent-sandbox` variant gives a disposable agent workspace your instructions and public skills, and nothing else: no shell, editor or Git config, no credentials, no private skills.
It deploys only:

- `~/.claude/CLAUDE.md`
- `~/.apm/apm.yml`, with public dependencies only
- a script that installs the APM version pinned in the inventory into `~/.local/share/agent-sandbox/apm` and runs `apm install -g --target agent-skills,claude --https`

For Claude Cloud, paste this into the environment's **Environment setup** field:

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
sh "$source/scripts/bootstrap-agent-sandbox.sh"
```

The bootstrap installs a SHA-256-verified chezmoi 2.65.0 on Linux x86_64 and initializes the variant without prompts.
It needs Git, curl, Node.js and Python 3.10+ with `venv`, and network access to GitHub and PyPI.

- Each setup run refreshes the checkout from `main`; keep it free of local edits.
- APM runs on the first apply and whenever the manifest or script changes; a failure is retried by the next apply.
- Existing Claude settings must be valid JSON, and `CLAUDE_CONFIG_DIR`, if set, must be `~/.claude`; otherwise APM refuses to run.
- The sandbox's own `.gitconfig`, `~/.claude.json` and session files stay its own.
- Use a separate home rather than converting a helm host: switching variants does not remove deployed files.

## First apply on an existing host

The first helm apply moves configuration that this repository now owns into a private backup, `~/.chezmoi-backups/pre-install.<timestamp>.<suffix>`, so stale plugins and configs cannot load next to the new setup.
It runs once (`run_once_before_00-cleanup-legacy-config.sh.tmpl`); nothing is deleted.

- It moves whole trees such as `~/.config/{nvim,zsh,git,mise,opencode,...}`, `~/.vim` and `~/.hammerspoon`, and dotfiles such as `.vimrc`, `.gitconfig`, `.profile` and the zsh startup files.
- History, credentials, runtimes, data and cache directories, and agent directories stay untouched.
- Preview with `chezmoi apply --dry-run`; the script prints its backup path, and you restore what you need from there.
  Treat backups as sensitive: a swept config can hold secrets.
- An existing `~/.zprofile` lands in the backup too; copy back what you need.
- After sweeping a running OpenCode, wait for its tasks, run `opencode service restart`, then reopen the TUI.
- A failed move stops the apply and retries next time; on `Permission denied`, fix the reported path's ownership, never with `sudo chezmoi apply`.
- To skip the cleanup on a host, create `~/.chezmoi-backups/.pre-install-complete` before applying.

## Slimming a former stem host

A host that leaves the `stem` group keeps what the stem setup left behind: an apply never deletes tool data.
`scripts/host-slim.sh` lists it, and moves it only when asked:

```sh
sh ~/.local/share/chezmoi/scripts/host-slim.sh           # dry run: what would move
sh ~/.local/share/chezmoi/scripts/host-slim.sh --apply   # move into ~/.chezmoi-backups/slim-<timestamp>
chezmoi apply
```

- It compares what a stem host manages with what this host manages, and adds the stem-only tool data: mise, zinit, Neovim and the personal skills clone.
- It also catches the old one-line `~/.profile` (`export TINY_CHEZMOI=1`), which hid `~/.bashrc` from bash logins; the next apply creates the current one.
- It never deletes, never touches apt or snap packages, and does nothing on stem hosts or in the agent sandbox.
- `--apply` prints the `--restore <backup>` command that moves everything back; it never overwrites a path that exists again.

## Public repository rules

This repository is public, so files are added by allowlist, never as whole application directories.

| Allowed | Never |
| --- | --- |
| reproducible configuration | auth files, tokens, credentials |
| public helper scripts | private keys, machine-local secrets |
| templates without secrets | sessions, state databases, history |
| encrypted secret templates | logs, caches, browser data, generated or vendored files |

Use `chezmoi add` for new files.
`README.md`, `LICENSE`, `AGENTS.md` and `docs/` stay in the repository only, through `.chezmoiignore`.

## Testing

| Test | Command | Needs |
| --- | --- | --- |
| unit | `just test` | chezmoi 2.66+, no network |
| Linux host, in a container | `just test-linux-host <host>` | Docker |
| agent sandbox, in a container | `just test-integration` | Docker with linux/amd64 |

`AGENTS.md` says when each runs: unit tests after every change, container tests once per pull request that touches what Linux hosts apply.

## More

- [Zsh](docs/zsh.md): startup order, `rc.d`, prompt, profiling, completion
- [Neovim and Vim](docs/neovim.md): editor selection, layout, plugin sync
- [OpenCode](docs/opencode.md): build and updates, theme, sidebar, quota recovery

Not managed here: WakaTime's API key (`wakatime --api-key` per host).
On macOS, `run_once_install-meslo-nerd-fonts.sh.tmpl` installs MesloLGS NF once, and the Ghostty config, which cmux also reads, selects it.
cmux's own appearance comes from an allowlist in `run_onchange_after_cmux-appearance.sh.tmpl` and its shortcuts from `~/.config/cmux/cmux.json`; its other preferences hold analytics and account entries and stay local.
