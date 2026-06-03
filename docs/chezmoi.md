# Chezmoi Policy

This repository is public. Add files by allowlist, not by whole application
directory.

Allowed:

- reproducible config
- public helper scripts
- templates without secrets
- encrypted secret templates

Denied:

- auth files
- tokens
- sessions
- state databases
- shell or application history
- logs
- caches
- browser data
- connector credentials
- generated vendor content

Use `chezmoi add` for new managed files when possible. Keep repo-only files
ignored by chezmoi, including `README.md`, `LICENSE`, and root `AGENTS.md`.

Use `.chezmoiignore` for target-path ignores. Source paths still use chezmoi
naming, for example `dot_config/` for `~/.config/`.
