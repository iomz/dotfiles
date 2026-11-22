set shell := ["sh", "-cu"]

# Scan source files for likely secrets.
secretlint:
    npm run lint:secrets

# Render both workstation OS variants and apply Cloud into an isolated home.
test:
    python3 -m unittest discover -s tests -v

# Opt-in real Ubuntu/dash/chezmoi/APM integration; requires Docker and network.
test-integration:
    sh tests/integration/run-claude-cloud.sh

# Point this checkout at its versioned Git hooks.
install-hooks:
    git config core.hooksPath .githooks

# Usage: just tool-add yq mise [version] --groups dev|--hosts oxalis
#        just tool-add mtr brew|apt|linux-brew [package]
# Add a tool entry, or an OS package to an existing entry, then chezmoi apply.
[positional-arguments]
tool-add *args:
    python3 -I scripts/tools.py add "$@"

# Update pinned mise versions, then chezmoi apply; --include-latest pins "latest".
[positional-arguments]
tool-bump *args:
    python3 -I scripts/tools.py bump "$@"
    git --no-pager diff --stat -- .chezmoidata/tools.toml

# Move a tool between mise and Homebrew on macOS, verifying before removal.
[positional-arguments]
tool-move *args:
    python3 -I scripts/tools.py move "$@"

# Re-sort the inventory into its derived sections after hand edits.
tool-fmt:
    python3 -I scripts/tools.py normalize

# Validate the inventory and preview what chezmoi would change.
tool-check:
    python3 -m unittest tests.test_tool_inventory
    chezmoi diff --no-pager

# Opt-in: apply to a fresh Ubuntu 26.04 container as a host profile; requires Docker.
test-linux-host host="sazanka" platform="":
    sh tests/integration/run-linux-host.sh {{host}} {{platform}}
