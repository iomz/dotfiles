# Codex

Managed Codex files are intentionally narrow.

Tracked:

- `~/.codex/AGENTS.md`
- personal custom skills, when added intentionally

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

Caveman mode is installed through Codex hooks, not through `AGENTS.md`.
`~/.codex/hooks.json` runs caveman activation at session start.
