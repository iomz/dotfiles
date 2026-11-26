# OpenCode

[Back to the README](../README.md)

chezmoi deploys OpenCode's configuration and plugins, and installs the binary with OpenCode's own v2 installer on macOS stem hosts.

## Install and update

- `.chezmoidata/tools.toml` declares `opencode` as a vendor install script: an apply runs `https://opencode.ai/v2/install --no-modify-path` while `~/.opencode/bin/opencode` is missing.
- `"update": "auto"` in `opencode.jsonc` lets OpenCode update itself through the same installer; restart the TUI after an update.
- zsh puts `~/.opencode/bin` first in `path`.
- Credentials and sessions stay on each host in `~/.local/share/opencode`; never copy them over.

## Which upstream version

By default the updater builds the highest stable `v2.<minor>.<patch>` tag of `anomalyco/opencode`, skipping prereleases, the stale `v2` branch and GitHub's "latest release" marker.

```sh
OPENCODE_UPDATE_REF=refs/tags/v2.1.1 opencode-update   # a specific tag
OPENCODE_UPDATE_REF=origin/dev opencode-update         # follow a branch
```

- An older target than the active build is not a downgrade: the active source stays.
- Divergent upstream history builds in isolation, with the same checks and rollback.
- The installed Bun must satisfy the target's `packageManager` requirement; the updater stops otherwise, and mise provides the right one.

## The patch and theme

`opencode-update` applies `~/.local/lib/opencode-patches/transparent-borders.patch` in an isolated worktree before building.
If the patch conflicts with upstream, the update stops and the active build stays.
The patch's SHA-256 is part of each build's manifest and name, so a changed patch rebuilds even on the same upstream commit.

The `cmux-transparent` theme keeps the main view, sidebar and command surfaces transparent, with opaque dialogs.
The patch adds a sidebar divider, a bold `YOU` label on your prompts, themed tool-block borders, scrollbar and attachment badges.
Build keeps a red accent and Plan a cyan one.

`scripts/opencode-theme-lab.html` previews colors on a dark terminal and exports preferences; it never changes the config.

| Keys | Action |
| --- | --- |
| `Ctrl+X`, then `P` | command palette |
| `Ctrl+P` / `Ctrl+N` | up / down in the input box |
| `Ctrl+B` / `Ctrl+F` | left / right one character |
| `Ctrl+K` | delete to the end of the line |

## Sidebar

| Panel | Shows |
| --- | --- |
| Dashboard (personal) | context meter, agent and model, estimated cost, Caveman state and version, tokens, activity, running subagents and background shells |
| Usage | Codex plan and quota bars, amber below 26 % and red below 11 % remaining |
| `opencode-git-plugin@0.3.0` | changed files and diff preview, refreshed every 8 s; `Ctrl+X`, `Shift+G` focuses it, arrows stage, `c` commits |
| `opencode-dir-tree-tui@1.0.6` | project tree with Git badges, last and collapsed at startup; `/dirtree-sidebar` configures it |

- Dashboard panels (`context`, `usage`, `session`, `caveman`, `tokens`, `activity`, `workers`) and colors are set in the plugin's `cli.json` options.
  The dashboard replaces the stock context section; when disabling it, also remove `-opencode.sidebar.context`.
- The dashboard reads OpenCode's cached data: no model calls, telemetry or extra login.
  Its footer shows the running TUI's version, so restart the TUI after an update.
- Only pinned package references and lock files are tracked; after-apply scripts restore the plugins' dependencies when missing or when a lock changes.
- Restart the TUI after plugin changes; no rebuild is needed.

The Usage panel reads the read-only ChatGPT usage endpoint.
With the standard **Sign in with ChatGPT** login it shows **Using ChatGPT plan** and a **Manage usage** link instead, since that login exposes no quota.
For percentages and quota recovery, choose **Codex device code (legacy)** or **Codex browser (legacy)** under `/connect` → OpenAI; nothing switches the login for you.

The Caveman server plugin reads `~/.agents/skills/caveman/SKILL.md`, so a new host needs `just apm-install` (and `just skills-pull`) and a `/reload`.
A missing Caveman skill shows as a plugin error and as `skill missing` in the dashboard's Caveman panel.

## Codex quota recovery

| Command | Does |
| --- | --- |
| `/codex-resume` | resume this session once after a confirmed quota failure |
| `/codex-resume --repeat` | keep resuming after every future quota failure |
| `/codex-resume --status` | show the mode and schedule |
| `/codex-resume --cancel` | cancel and leave repeat mode |

- When the quota resets, the plugin queues `Resume from where you paused.` in the same session, keeping its model, agent and permissions.
  It waits for the exhausted window plus two seconds, then checks every 10 seconds, without model calls.
- Recovery runs in the server's per-project plugin, so only while that project's server runs; the server stops a project after 60 idle minutes.
  On macOS, the `io.github.iomz.opencode-codex-resume-wake` LaunchAgent boots due projects every 60 seconds; failures go to `~/Library/Logs/opencode-codex-resume-wake.log`.
  Linux hosts are not woken.
- A manual prompt cancels the pending timer but keeps repeat mode; changing model or agent, moving or deleting the session, or cancelling disables recovery.
- Missing or unrecognized quota data never triggers a resume; the endpoint is internal and can change.
- Schedules live in OpenCode's plugin storage and survive server restarts, but cannot wake a sleeping machine.

## Tests

```sh
python3 -m unittest tests/test_opencode_borders.py tests/test_opencode_codex_resume_wake.py
bun test tests/opencode-sidebar.test.ts
node --test tests/opencode-caveman.test.mjs tests/opencode-codex-resume.test.mjs
```

- SDK check: add `OPENCODE_PLUGIN_NODE_MODULES="$HOME/.config/opencode/cli-plugins/codex-quota-sidebar/node_modules"` and run `node --test tests/opencode-codex-resume*.test.mjs`.
- Renderer check: from the build checkout's `packages/tui`, run `OPENCODE_TUI_SOURCE="$PWD" bun test ~/.local/share/chezmoi/tests/opencode-sidebar-render.test.ts`.
