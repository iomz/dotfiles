# AGENTS.md

## Repository Purpose

This repository is a public chezmoi source for personal dotfiles.

The repository should contain reproducible configuration and public-safe helper
scripts only. It must not contain credentials, local state, history, caches, or
machine-specific secrets.

## Public Dotfiles Safety

- Prefer explicit allowlists over adding whole application directories.
- Inspect files before adding them to chezmoi.
- Never publish auth files, tokens, session data, state databases, history,
  logs, caches, browser data, or connector credentials.
- Use encrypted templates for secrets.
- Keep generated, vendored, and system-managed content out of Git unless there
  is a clear reason to own it here.
- For Codex, track repo/global instruction files and personal custom skills
  only. Do not track `~/.codex/config.toml`, hooks, sessions, auth, caches, or
  `~/.codex/skills/.system`.

## Chezmoi Rules

- Use `chezmoi add` for new managed files when possible.
- Keep repo-only files such as `README.md`, `LICENSE`, and this `AGENTS.md`
  ignored by chezmoi so they do not apply into `$HOME`.
- Use source-path names intentionally, for example `dot_config/` for
  `~/.config/`.

## Working Tree Rules

- Check `git status --short` before edits.
- Treat unrelated dirty files as separate work. Do not stage, commit, rewrite,
  or revert them unless the user explicitly asks.
- For refactors, classify changes by purpose and keep commits small enough to
  review. If existing dirty changes overlap the refactor, inspect the diff and
  continue only when the intended ownership is clear.

## Git Commits

Always use Conventional Commits unless repository history clearly uses another
strict format.

Use lowercase type/scope style, imperative subject, and no trailing period.

Examples:

- `feat(certbot): add cloudflare renewal migration flag`
- `chore(git): stop tracking vault password file`
- `docs(certbot): document forced cloudflare renewal`
