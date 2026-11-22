#!/bin/sh
# Opt-in: apply these dotfiles to a fresh Ubuntu container as a host profile.
# Requires Docker and network access. Usage:
#   run-linux-host.sh [host-profile] [platform]   e.g. sazanka linux/amd64
set -eu
source_dir=$(CDPATH= cd "$(dirname "$0")/../.." && pwd)
host=${1:-sazanka}
platform=${2:-}
exec docker run --rm ${platform:+--platform "$platform"} \
  --mount "type=bind,source=$source_dir,target=/dotfiles,readonly" \
  ubuntu:26.04 sh /dotfiles/tests/integration/linux-host.sh "$host"
