#!/bin/sh
# Run from Cloud's environment setup script, before Claude starts.
set -eu

# Cloud's observed platform. No workstation bootstrap or profile machinery.
if [ "$(uname -s)" != Linux ] || [ "$(uname -m)" != x86_64 ]; then
  echo 'claude-cloud bootstrap requires Linux x86_64' >&2
  exit 1
fi

source_dir=$(CDPATH= cd "$(dirname "$0")/.." && pwd)
bin_dir="$HOME/.local/bin"
version=2.65.0
asset="chezmoi_${version}_linux_amd64.tar.gz"
checksums="chezmoi_${version}_checksums.txt"
release="https://github.com/twpayne/chezmoi/releases/download/v${version}"

mkdir -p "$bin_dir"
installed_version=$("$bin_dir/chezmoi" --version 2>/dev/null || true)
case "$installed_version" in
  "chezmoi version v${version},"*) ;;
  *)
    work=$(mktemp -d "${TMPDIR:-/tmp}/chezmoi-cloud.XXXXXX")
    # Only remove known files created by this bootstrap, never a broad tree.
    trap 'rm -f "$work/$asset" "$work/$checksums" "$work/selected-checksum" "$work/chezmoi"; rmdir "$work"' 0
    trap 'exit 1' 1 2 15
    curl -fsSL "$release/$asset" -o "$work/$asset"
    curl -fsSL "$release/$checksums" -o "$work/$checksums"
    # Select exactly this asset; fail on a missing or duplicate checksum entry.
    if ! awk -v asset="$asset" '$2 == asset { print; found++ } END { if (found != 1) exit 1 }' \
      "$work/$checksums" > "$work/selected-checksum"; then
      echo 'missing or duplicate chezmoi checksum entry' >&2
      exit 1
    fi
    (cd "$work" && sha256sum -c selected-checksum)
    tar -xzf "$work/$asset" -C "$work" chezmoi
    install -m 0755 "$work/chezmoi" "$bin_dir/chezmoi"
    ;;
esac

# Explicit source and selector work even when setup cwd is outside HOME.
# Defaults keep initialization noninteractive with stdin closed.
CHEZMOI_VARIANT=claude-cloud "$bin_dir/chezmoi" --source "$source_dir" \
  init --apply --no-tty --promptDefaults
