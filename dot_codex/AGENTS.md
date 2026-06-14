# Inspection

For commands that may produce large output, use:

`runlog <command>`

Then summarize the failure and inspect the log only as needed.

Before diagnosing environment issues, run `ai-check`.

# Git

Always use Conventional Commits for commit messages unless repository history clearly uses another strict format.

Use lowercase type/scope style, imperative subject, and no trailing period.

Examples:

- feat(certbot): add cloudflare renewal migration flag
- chore(git): stop tracking vault password file
- docs(certbot): document forced cloudflare renewal

Add detailed commit bodies explaining:

- what changed
- why it changed
- architectural impact
- migration notes when relevant

Keep commits small and reviewable.

Do not rewrite history unless explicitly requested.

Do not force-push unless explicitly requested.

# Design

Prefer simple designs.

Respect responsibility boundaries.

Treat ideas as drafts rather than finished designs.

When proposing abstractions, explain in the docs:

- why they are needed
- alternatives
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

Push domain-specific logic to plugins, adapters, or external systems whenever possible.

Do not require external tools to implement repository-specific interfaces unless there is a compelling reason.

# Safety

Before running destructive operations, explain the impact and ask for confirmation.

Examples include:

- rm -rf
- git reset --hard
- git clean -fd
- docker system prune
- terraform destroy

Prefer reversible operations when possible.

# Evaluation

Do not automatically agree with proposals.

Identify:

- assumptions
- risks
- alternatives
- maintenance burden

before implementation.

Prefer long-term maintainability over short-term cleverness.
