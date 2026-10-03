#!/bin/sh
# Opt-in: Docker, network access, and Linux amd64 execution/emulation required.
set -eu
source_dir=$(CDPATH= cd "$(dirname "$0")/../.." && pwd)
exec docker run --rm --platform linux/amd64 \
  --mount "type=bind,source=$source_dir,target=/dotfiles,readonly" \
  ubuntu:24.04 sh /dotfiles/tests/integration/claude-cloud.sh
