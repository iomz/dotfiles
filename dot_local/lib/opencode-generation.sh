#!/usr/bin/env bash

opencode_die() {
  printf 'opencode: ERROR: %s\n' "$*" >&2
  return 1
}

opencode_realpath() {
  python3 - "$1" <<'PY'
import os, sys
print(os.path.realpath(sys.argv[1]))
PY
}

opencode_atomic_symlink() {
  local target=$1 link=$2
  python3 - "$target" "$link" <<'PY'
import os, sys, uuid
target, link = sys.argv[1:]
tmp = f"{link}.tmp.{os.getpid()}.{uuid.uuid4().hex}"
try:
    os.symlink(target, tmp)
    os.replace(tmp, link)
finally:
    try: os.unlink(tmp)
    except FileNotFoundError: pass
PY
}

opencode_link_target() {
  [[ -L $1 ]] || return 1
  local target
  target=$(readlink "$1") || return 1
  [[ $target = /* ]] || target="$(dirname "$1")/$target"
  opencode_realpath "$target"
}

opencode_generation_verify() {
  local gen=$1 releases_real gen_real
  [[ -d $gen && ! -L $gen ]] || opencode_die "generation is not a real directory: $gen" || return
  releases_real=$(opencode_realpath "$OPENCODE_ROOT/releases") || return
  gen_real=$(opencode_realpath "$gen") || return
  [[ $(dirname "$gen_real") = "$releases_real" ]] || opencode_die "generation escapes releases/: $gen" || return
  python3 - "$gen_real" <<'PY'
import hashlib, json, os, sys
root = sys.argv[1]
try:
    with open(os.path.join(root, "manifest.json"), encoding="utf-8") as f:
        m = json.load(f)
    rel = m["executable"]
    if not isinstance(rel, str) or os.path.isabs(rel) or ".." in rel.split("/"):
        raise ValueError("unsafe executable path")
    exe = os.path.realpath(os.path.join(root, rel))
    if os.path.commonpath((root, exe)) != root or not os.path.isfile(exe) or not os.access(exe, os.X_OK):
        raise ValueError("executable missing or escapes generation")
    with open(exe, "rb") as f:
        digest = hashlib.file_digest(f, "sha256").hexdigest()
    if digest != m["sha256"]:
        raise ValueError("executable SHA-256 does not match manifest")
    if not m.get("version") or not m.get("source_commit"):
        raise ValueError("manifest lacks version or source commit")
    print(exe)
except Exception as e:
    print(f"invalid generation {root}: {e}", file=sys.stderr)
    raise SystemExit(1)
PY
}

opencode_lock_acquire() {
  OPENCODE_LOCK="$OPENCODE_ROOT/operation.lock"
  if mkdir "$OPENCODE_LOCK" 2>/dev/null; then
    printf '%s\n' "$$" > "$OPENCODE_LOCK/pid"
    return 0
  fi
  if [[ -f $OPENCODE_LOCK/pid ]]; then
    local pid
    pid=$(cat "$OPENCODE_LOCK/pid" 2>/dev/null || true)
    if [[ $pid =~ ^[0-9]+$ ]] && ! kill -0 "$pid" 2>/dev/null; then
      opencode_die "stale lock at $OPENCODE_LOCK (pid $pid); inspect it, then remove manually"
      return 1
    fi
  fi
  opencode_die "another update/rollback may be running; inspect lock: $OPENCODE_LOCK"
}

opencode_lock_release() {
  [[ ${OPENCODE_LOCK:-} = "$OPENCODE_ROOT/operation.lock" && -d $OPENCODE_LOCK ]] || return 0
  local pid
  pid=$(cat "$OPENCODE_LOCK/pid" 2>/dev/null || true)
  [[ $pid = $$ ]] || return 0
  rm -f "$OPENCODE_LOCK/pid" && rmdir "$OPENCODE_LOCK" 2>/dev/null || true
}

opencode_recover_transaction() {
  local journal="$OPENCODE_ROOT/pointer-transaction"
  [[ -e $journal ]] || return 0
  python3 - "$journal" <<'PY'
import json, sys
with open(sys.argv[1], encoding="utf-8") as f: j=json.load(f)
for k in ("old_active", "old_previous", "new_active"):
    if not isinstance(j.get(k), str) or "/" in j[k] or j[k] in ("", ".", ".."):
        raise SystemExit("invalid pointer transaction journal")
PY
  local old_active old_previous new_active active_target
  old_active=$(python3 -c 'import json,sys;print(json.load(open(sys.argv[1]))["old_active"])' "$journal")
  old_previous=$(python3 -c 'import json,sys;print(json.load(open(sys.argv[1]))["old_previous"])' "$journal")
  new_active=$(python3 -c 'import json,sys;print(json.load(open(sys.argv[1]))["new_active"])' "$journal")
  active_target=$(opencode_link_target "$OPENCODE_ROOT/active") || opencode_die 'cannot recover transaction: active is not a symlink' || return
  case "$(basename "$active_target")" in
    "$new_active") opencode_atomic_symlink "$OPENCODE_ROOT/releases/$old_active" "$OPENCODE_ROOT/previous" ;;
    "$old_active") opencode_atomic_symlink "$OPENCODE_ROOT/releases/$old_previous" "$OPENCODE_ROOT/previous" ;;
    *) opencode_die "cannot recover transaction: active points to unexpected generation $(basename "$active_target")"; return 1 ;;
  esac
  rm -f "$journal"
  opencode_prune_generations || printf 'opencode: warning: recovery completed, but extra generations could not be pruned\n' >&2
}

opencode_swap_pointers() {
  local new_active=$1 new_previous=$2
  local active_link="$OPENCODE_ROOT/active" previous_link="$OPENCODE_ROOT/previous"
  local old_active old_previous
  old_active=$(basename "$(opencode_link_target "$active_link")") || opencode_die 'active pointer invalid' || return
  old_previous=$(basename "$(opencode_link_target "$previous_link")") || opencode_die 'previous pointer invalid' || return
  python3 - "$OPENCODE_ROOT/pointer-transaction" "$old_active" "$old_previous" "$new_active" <<'PY'
import json, os, sys, uuid
path, old_active, old_previous, new_active = sys.argv[1:]
tmp=f"{path}.tmp.{os.getpid()}.{uuid.uuid4().hex}"
with open(tmp, "x", encoding="utf-8") as f:
    json.dump({"old_active":old_active,"old_previous":old_previous,"new_active":new_active}, f)
    f.write("\n"); f.flush(); os.fsync(f.fileno())
os.replace(tmp, path)
PY
  opencode_atomic_symlink "$OPENCODE_ROOT/releases/$new_previous" "$previous_link" || return
  opencode_atomic_symlink "$OPENCODE_ROOT/releases/$new_active" "$active_link" || return
  [[ $(basename "$(opencode_link_target "$active_link")") = "$new_active" ]] || return 1
  [[ $(basename "$(opencode_link_target "$previous_link")") = "$new_previous" ]] || return 1
  rm -f "$OPENCODE_ROOT/pointer-transaction"
}

opencode_prune_generations() {
  local active previous entry real base failed=0
  active=$(opencode_link_target "$OPENCODE_ROOT/active") || return 1
  previous=$(opencode_link_target "$OPENCODE_ROOT/previous") || return 1
  [[ $(dirname "$active") = "$OPENCODE_ROOT/releases" && $(dirname "$previous") = "$OPENCODE_ROOT/releases" ]] || return 1
  for entry in "$OPENCODE_ROOT"/releases/* "$OPENCODE_ROOT"/releases/.staging-*; do
    [[ -e $entry || -L $entry ]] || continue
    [[ -d $entry && ! -L $entry ]] || { printf 'opencode: retain unexpected release entry: %s\n' "$entry" >&2; failed=1; continue; }
    real=$(opencode_realpath "$entry") || { failed=1; continue; }
    [[ $(dirname "$real") = "$OPENCODE_ROOT/releases" ]] || { printf 'opencode: retain unsafe release path: %s\n' "$entry" >&2; failed=1; continue; }
    base=$(basename "$real")
    if [[ $base = .staging-* ]]; then
      [[ $entry = "$OPENCODE_ROOT/releases/$base" ]] || { printf 'opencode: retain unsafe staging path: %s\n' "$entry" >&2; failed=1; continue; }
      rm -rf -- "$real" || { printf 'opencode: could not clean staging directory %s\n' "$real" >&2; failed=1; }
      continue
    fi
    [[ $real = "$active" || $real = "$previous" ]] && continue
    [[ $base != '' && $real = "$OPENCODE_ROOT/releases/$base" ]] || { printf 'opencode: retain unsafe deletion target: %s\n' "$real" >&2; failed=1; continue; }
    if [[ ! -f $real/manifest.json ]] || ! opencode_generation_verify "$real" >/dev/null; then
      printf 'opencode: retain unrecognized or invalid release directory: %s\n' "$real" >&2
      failed=1
      continue
    fi
    rm -rf -- "$real" || { printf 'opencode: could not prune %s\n' "$real" >&2; return 1; }
  done
  return "$failed"
}
