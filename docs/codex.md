# Codex

Managed Codex files are intentionally narrow.

Tracked:

- `~/.codex/AGENTS.md`
- inspected personal skills under `~/.codex/skills/<name>/`, when added intentionally

Not tracked:

- `~/.codex/config.toml`
- `~/.codex/auth.json`
- `~/.codex/hooks.json`
- `~/.codex/hooks/`
- `~/.codex/sessions/`
- `~/.codex/history.jsonl`
- `~/.codex/cache/`
- `~/.codex/skills/.system/`
- state databases and WAL/SHM files

## Skill Ownership

| Category | Location | Owner | Chezmoi policy |
|---|---|---|---|
| Personal and public-safe | `~/.codex/skills/<name>/` | chezmoi | Track only after inspecting every file |
| Private or machine-local | `~/.codex/skills/.local/<name>/` | local machine | Always ignored |
| Codex system skills | `~/.codex/skills/.system/` | Codex | Always ignored |
| Generated skill cache | `~/.codex/skills/.cache/` | Codex or skill tooling | Always ignored |
| Nested repository metadata and dependencies | `.git/`, `node_modules/` below a skill | upstream tooling | Always ignored |

Keep source code for reusable public skills in its own repository when it has an
independent lifecycle. Chezmoi should manage only intentionally selected personal
skills, not installer output, cloned repository metadata, or dependencies.

Caveman mode is installed through Codex hooks, not through `AGENTS.md`.
`~/.codex/hooks.json` runs caveman activation at session start.

Append the folloing to `~/.codex/config.toml`:

```toml
[features]
codex_git_commit = true

[git]
commit_attribution = "Co-authored-by: Codex <noreply@openai.com>"
```
