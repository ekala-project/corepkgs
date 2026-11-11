# shellcheck shell=bash
# Remove /etc files that the previous generation installed and the new one
# no longer provides.
#
# Usage: prune-etc <old-static> <new-static> [etc-dir]
#
# /etc entries are copied out of the static tree, so ownership is decided
# by content: a file is removed only while it is still identical to what
# the old generation installed (or is a symlink to it). Anything an
# administrator changed is kept and reported. The systemd unit
# directories are reconciled separately (sync-unit-dir) and skipped here.
set -eu

old=$1
new=$2
etc=${3:-/etc}

[ -d "$old" ] || exit 0
old=$(readlink -f "$old")
new=$(readlink -f "$new" 2>/dev/null || printf '%s' "$new")
[ "$old" = "$new" ] && exit 0

removed_dirs=()

# Parent directory of a relative path, empty for top-level entries.
parent() {
  case "$1" in
    */*) printf '%s' "${1%/*}" ;;
  esac
}

while IFS= read -r -d '' src; do
  rel=${src#"$old"/}

  case "$rel" in
    systemd/system/* | systemd/user/*) continue ;;
  esac

  # Still provided by the new generation: it was just copied over.
  if [ -e "$new/$rel" ] || [ -L "$new/$rel" ]; then
    continue
  fi

  dest="$etc/$rel"
  if [ -L "$dest" ]; then
    target=$(readlink "$dest")
    case "$target" in
      "$src" | "$old/$rel" | "/etc/static/$rel")
        rm -f "$dest"
        removed_dirs+=("$(parent "$rel")")
        ;;
      *) echo "ekaos: keeping $dest: no longer configured, but it was replaced" >&2 ;;
    esac
  elif [ -f "$dest" ]; then
    if cmp -s "$src" "$dest"; then
      rm -f "$dest"
      removed_dirs+=("$(parent "$rel")")
    else
      echo "ekaos: keeping $dest: no longer configured, but it was modified" >&2
    fi
  fi
done < <(find -L "$old" ! -type d -print0)

# Drop directories that became empty, walking up, but only ones the new
# generation does not provide.
for dir in "${removed_dirs[@]}"; do
  while [ -n "$dir" ]; do
    [ -d "$new/$dir" ] && break
    rmdir "$etc/$dir" 2>/dev/null || break
    dir=$(parent "$dir")
  done
done
