# Inspection

Prefer narrow queries before broad scans.

Use `runlog` for commands expected to produce more than 200 lines, unless they may run longer than 10 seconds.

Run long commands directly with bounded output and poll their session.

Run `ai-check` before diagnosing environment issues.

# Git

Use Conventional Commits unless repository history requires another strict format.

Use lowercase type and scope, an imperative subject, and no trailing period.

Examples:

- feat(certbot): add cloudflare renewal migration flag
- chore(git): stop tracking vault password file
- docs(certbot): document forced cloudflare renewal

For non-trivial commits, add a body explaining:

- what changed
- why it changed
- architectural impact
- migration requirements, when relevant

Keep commits small and reviewable.

Do not rewrite history unless explicitly requested.

Run GitHub CLI operations with elevated permissions by default.
Do not diagnose sandbox `gh` authentication unless elevated `gh` also fails.

Do not push commits or branches unless explicitly authorized.
Permission to commit does not imply permission to push.
Requests to publish, open a pull request, or update a remote pull request authorize pushing required commits.

## AI Attribution

For commits materially authored by Codex in repositories owned by this user, append:

```text
Co-authored-by: Codex <noreply@openai.com>
```

For external repositories, follow repository policy and disclose material AI assistance in the pull request body.

Minor research, review, and mechanical assistance require no attribution.

# Markdown Editing

Preserve existing line breaks, paragraph structure, and document shape unless the requested change requires otherwise.

Make the smallest semantic diff possible.

Do not auto-wrap or reflow prose to a fixed column width.

# Design

Prefer simple designs with clear responsibility boundaries.

Treat proposed designs as drafts subject to evaluation.

When proposing an abstraction, document:

- why it is needed
- viable alternatives
- tradeoffs

Prefer:

- explicit interfaces
- plain files
- standard tools
- composition over inheritance
- plugins over feature flags

Avoid:

- magic
- unnecessary dependencies
- speculative abstractions
- hidden side effects
- global mutable state

Keep the core thin.
Place domain-specific logic in plugins, adapters, or external systems where practical.

Do not make external tools implement repository-specific interfaces without a documented architectural reason.

# Safety

Before running a destructive operation, explain its impact and request confirmation.

Examples:

- `rm -rf`
- `git reset --hard`
- `git clean -fd`
- `docker system prune`
- `terraform destroy`

Prefer reversible operations.

# Evaluation

Do not accept proposals without evaluation.

Before implementation, identify:

- assumptions
- risks
- alternatives
- maintenance burden

Prefer long-term maintainability over short-term cleverness.