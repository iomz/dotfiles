# Repository Conventions

Prefer narrow queries before broad scans.

When a repository’s documentation and its existing code disagree, follow the conventions used in the existing code, and in your final reply point out each inconsistency you found between the documentation and the code.
This applies to descriptive conventions, not security requirements, action permissions, or explicit requests to change existing behavior.
Do not rewrite working code merely to match stale documentation.

# Design and Evaluation

Before implementation, evaluate assumptions, risks, alternatives, and maintenance burden.
Treat proposed designs as drafts; prefer long-term maintainability over cleverness.
Justify abstractions with their need, viable alternatives, and tradeoffs.

Prefer simple designs, clear responsibility boundaries, explicit interfaces, plain files, standard tools, composition over inheritance, and plugins over feature flags.
Avoid magic, unnecessary dependencies, speculative abstractions, hidden side effects, and global mutable state.
Keep the core thin; place domain-specific logic in plugins, adapters, or external systems where practical.
Do not make external tools implement repository-specific interfaces without a documented architectural reason.

# Git and GitHub

Use Conventional Commits unless repository history requires another strict format: lowercase type and scope, imperative subject, no trailing period.
Use Conventional Commit-style PR titles with lowercase type and optional scope.
Keep commits small and reviewable; for non-trivial changes, explain what changed, why, architectural impact, and any migration requirements in the body.
Prefer branch prefixes such as `fix/`, `feat/`, or `chore/`, following user or repository conventions.

Use one `git commit -m` argument per paragraph and trailer; never embed literal `\\n`, `\\r`, or shell escape sequences to create paragraphs.
Before pushing or rewriting commits, inspect `git log -1 --format=%B` and correct literal `\\n` or `\\r` sequences.
Do not rewrite history unless explicitly requested.

Use authenticated `gh` directly for GitHub write operations.
Do not push commits or branches unless explicitly authorized; permission to commit does not imply permission to push.
Requests to publish, open a pull request, or update a remote pull request authorize pushing required commits.

For commits materially authored by an AI tool in repositories owned by this user, append a `Co-authored-by` trailer naming that tool in its specified format.
For external repositories, follow repository policy and disclose material AI assistance in the pull request body.
Minor research, review, and mechanical assistance require no attribution.

# Markdown Editing

Make the smallest semantic diff; preserve line breaks, paragraph structure, and document shape unless the requested change requires otherwise.
Do not auto-wrap or reflow prose to a fixed column width.
Prefer one sentence per source line when editing prose; preserve existing wrapping outside touched paragraphs unless reflow is requested.
When providing Markdown source containing fenced code blocks, use an outer backtick fence longer than every nested fence.

# Safety

Before running a destructive operation, explain its impact and request confirmation.
Prefer reversible operations.
