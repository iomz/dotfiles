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

# GitHub access for private sources goes through gh only: run gh auth login once.
[private]
gh-login:
    @gh auth status >/dev/null 2>&1 || { echo "Not logged in to GitHub: run gh auth login first" >&2; exit 1; }

# Install the APM skills and plugins pinned in ~/.apm/apm.yml.
apm-install: gh-login
    #!/bin/sh
    set -eu
    # APM reads private sources such as iomz/brain-vault with this token.
    GITHUB_APM_PAT=$(gh auth token)
    export GITHUB_APM_PAT
    exec apm install -g

# Stops on local changes or another branch; never resets, stashes or forces.
# Clone iomz/skills for the ~/.claude/skills links, or fast-forward it to main.
skills-pull: gh-login
    #!/bin/sh
    set -eu
    dir="$HOME/.local/share/agent-skills"
    url=https://github.com/iomz/skills.git
    # HTTPS through gh's credentials, so no SSH key is needed.
    git_gh() { git -c credential.helper= -c 'credential.helper=!gh auth git-credential' "$@"; }
    if [ ! -e "$dir" ]; then
        git_gh clone --branch main "$url" "$dir"
        exit
    fi
    if [ "$(git -C "$dir" config --get remote.origin.url)" = git@github.com:iomz/skills.git ]; then
        git -C "$dir" remote set-url origin "$url"
    fi
    branch=$(git -C "$dir" symbolic-ref --quiet --short HEAD || echo "detached HEAD")
    if [ "$branch" != main ]; then
        echo "skills-pull: $dir is on $branch, not main; switch back by hand" >&2
        exit 1
    fi
    changes=$(git -C "$dir" status --porcelain)
    if [ -n "$changes" ]; then
        printf '%s\n' "$changes" >&2
        echo "skills-pull: $dir has local changes; edit skills in a separate checkout" >&2
        exit 1
    fi
    git_gh -C "$dir" pull --ff-only origin main
