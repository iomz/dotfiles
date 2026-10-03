# AGENTS.md

## Repository Purpose

This repository is a public chezmoi source for personal dotfiles.

The repository should contain reproducible configuration and public-safe helper scripts only.
It must not contain credentials, local state, history, caches, or machine-specific secrets.

## Public Dotfiles Safety

- Prefer explicit allowlists over adding whole application directories.
- Inspect files before adding them to chezmoi.
- Never publish auth files, tokens, session data, state databases, history, logs, caches, browser data, or connector credentials.
- Use encrypted templates for secrets.
- Keep generated, vendored, and system-managed content out of Git unless there is a clear reason to own it here.
- For Codex, track repo/global instruction files and personal custom skills only.
  Do not track `~/.codex/config.toml`, hooks, sessions, auth, caches, or `~/.codex/skills/.system`.
- Global instructions for Codex and Claude Code share one canonical tool-neutral source, `.chezmoitemplates/AGENTS.md`.
  `private_dot_codex/AGENTS.md.tmpl` appends Codex-only rules and `private_dot_claude/CLAUDE.md.tmpl` renders the neutral text at Claude's required user-global path.
  Put tool-specific rules in the matching template, not in the shared file.
- For Claude Code, track only `~/.claude/CLAUDE.md`, generated from the canonical shared source.
  `~/.claude/AGENTS.md` is not a user-global instruction location.
  Do not track `~/.claude/settings.json`, skills, agents, hooks, plugins, sessions, or caches; APM deploys skills, agents, and hooks there.
- Claude Cloud owns its Git signing configuration and launcher/session/synced-skill state.
  Never deploy `.gitconfig`, `.claude.json`, or an `exact_` Claude directory in the Cloud variant.
- Treat `~/.agents/skills` as a shared deployment surface.
  Track only explicitly allowlisted, personally authored, public-safe skills.
  Keep third-party skills, installer lock files, and package-manager output outside chezmoi.
- If APM manages shared skills, chezmoi may track an inspected public-safe manifest with pinned SHAs, but never the generated `~/.apm/apm.lock.yaml`, `~/.apm/apm_modules` or deployed copies.

## Chezmoi Rules

- Use `chezmoi add` for new managed files when possible.
- Keep repo-only files such as `README.md`, `LICENSE`, and this `AGENTS.md` ignored by chezmoi so they do not apply into `$HOME`.
- Use source-path names intentionally, for example `dot_config/` for `~/.config/`.

## Working Tree Rules

- Check `git status --short` before edits.
- Treat unrelated dirty files as separate work.
  Do not stage, commit, rewrite, or revert them unless the user explicitly asks.
- For refactors, classify changes by purpose and keep commits small enough to review.
  If existing dirty changes overlap the refactor, inspect the diff and continue only when the intended ownership is clear.

## Git Commits

Use Conventional Commits with lowercase type and scope, an imperative subject, and no trailing period, unless repository history clearly uses another strict format.
