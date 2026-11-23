#!/bin/sh
# One-time slimming of a leaf host that was deployed with the stem setup.
# Lists what a stem host has and this host no longer needs; --apply moves it
# into a private backup. Never deletes, never touches apt or snap packages,
# and is not run by chezmoi apply.
#
# usage: sh ~/.local/share/chezmoi/scripts/host-slim.sh [--apply]
set -eu

apply=
case ${1-} in
  '') ;;
  --apply) apply=yes ;;
  -h | --help) sed -n '2,7p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
  *) echo "host-slim: unknown option: $1" >&2; exit 2 ;;
esac

chezmoi=$(command -v chezmoi || true)
for candidate in "$HOME/.local/bin/chezmoi" "$HOME/bin/chezmoi"; do
  [ -n "$chezmoi" ] || { [ -x "$candidate" ] && chezmoi=$candidate; } || true
done
if [ -z "$chezmoi" ]; then
  echo 'host-slim: chezmoi not found' >&2
  exit 1
fi

variant=$("$chezmoi" execute-template '{{ includeTemplate "variant" . }}')
if [ "$variant" != helm ]; then
  echo "host-slim: nothing to slim on an $variant host"
  exit 0
fi
host=$("$chezmoi" execute-template '{{ .host }}')
if [ "$("$chezmoi" execute-template '{{ includeTemplate "is-stem" . }}')" = true ]; then
  echo "host-slim: $host is a stem host; nothing to slim"
  exit 0
fi
stem=$("$chezmoi" execute-template \
  '{{ range $name, $h := .hosts }}{{ if has "stem" ($h.groups | default list) }}{{ $name }}{{ "\n" }}{{ end }}{{ end }}' | sed -n 1p)
if [ -z "$stem" ]; then
  echo 'host-slim: the inventory declares no stem host to compare with' >&2
  exit 1
fi

# Whole trees of tools that only stem hosts use. Packages are left alone.
trees='.config/mise
.local/share/mise
.local/state/mise
.cache/mise
.local/share/zinit
.cache/zinit
.config/nvim
.local/share/nvim
.local/state/nvim
.cache/nvim
.local/share/agent-skills'

# Managed files and links that only stem hosts get, one by one: a stem-only
# directory such as ~/.claude/skills can also hold files that are not ours.
# --override-data needs chezmoi 2.66 or later.
# Byte order for sort and comm: GNU comm rejects locale-collated input.
managed() { "$chezmoi" "$@" managed --include files,symlinks | LC_ALL=C sort; }
tmp=$(mktemp -d "${TMPDIR:-/tmp}/host-slim.XXXXXX")
trap 'rm -f "$tmp/stem" "$tmp/here"; rmdir "$tmp"' 0
managed --override-data "{\"host\":\"$stem\"}" > "$tmp/stem"
managed > "$tmp/here"
files=$(LC_ALL=C comm -23 "$tmp/stem" "$tmp/here")

# Before the stem/leaf split, leaf hosts got a ~/.profile that only set
# TINY_CHEZMOI, which hides ~/.bashrc from bash logins; chezmoi creates the
# current one once it is gone.
legacy_profile=
if [ -f "$HOME/.profile" ] && ! grep -qv -e '^export TINY_CHEZMOI=1$' -e '^[[:space:]]*$' "$HOME/.profile"; then
  legacy_profile=.profile
fi

nl='
'
selected=
under_tree() {
  for tree in $trees; do
    case $1 in "$tree"/*) return 0 ;; esac
  done
  return 1
}
oldifs=$IFS
IFS=$nl
for path in $trees $files $legacy_profile; do
  [ -e "$HOME/$path" ] || [ -L "$HOME/$path" ] || continue
  # A file inside a tree moves with its tree.
  ! under_tree "$path" || continue
  selected="$selected$path$nl"
done
IFS=$oldifs

if [ -z "$selected" ]; then
  echo "host-slim: $host is a leaf host; nothing to slim"
  exit 0
fi

echo "host-slim: $host is a leaf host; compared with stem host $stem"
if [ -z "$apply" ]; then
  echo 'Would move (dry run; add --apply to move them into a backup):'
else
  backup="$HOME/.chezmoi-backups/slim-$(date -u +%Y%m%dT%H%M%SZ)"
  mkdir -p "$HOME/.chezmoi-backups"
  (umask 077 && mkdir "$backup")
  echo "Moving into $backup:"
fi
IFS=$nl
for path in $selected; do
  size=$(du -sh "$HOME/$path" 2>/dev/null | cut -f1)
  printf '  %6s  %s\n' "${size:-?}" "$path"
  if [ -n "$apply" ]; then
    mkdir -p "$backup/$(dirname "$path")"
    mv "$HOME/$path" "$backup/$path"
    printf '%s\n' "$path" >> "$backup/MOVED"
  fi
done
IFS=$oldifs

if [ -n "$apply" ]; then
  echo "Done. Run chezmoi apply next, then start a new shell."
  echo "To restore: cp -Rp \"$backup/.\" \"\$HOME/\" && rm \"\$HOME/MOVED\""
fi
