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
