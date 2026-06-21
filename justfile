set shell := ["sh", "-cu"]

# Scan source files for likely secrets.
secretlint:
    npm run lint:secrets

# Point this checkout at its versioned Git hooks.
install-hooks:
    git config core.hooksPath .githooks

