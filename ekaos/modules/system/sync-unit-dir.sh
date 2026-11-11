# Reconcile a mutable systemd unit directory (e.g. /etc/systemd/system)
# against the declarative tree in /etc/static.
#
# Usage: sync-unit-dir <static-dir> <dest-dir>
#   e.g. sync-unit-dir /etc/static/systemd/system /etc/systemd/system
#
# Ownership is decided by where an entry points:
#   - a symlink into <static-dir>/ is managed by the configuration and is
#     created, updated or removed to match the current generation;
#   - anything else (`systemctl enable` links, `systemctl mask` links to
#     /dev/null, `systemctl edit` drop-ins, hand-written units) belongs to the
#     administrator and is never modified.
#
# Before the first sync (no marker file), the directory was populated by the
# old `cp -rfL /etc/static/* /etc/` activation and the imperative getty,
# networkd and package-unit links. In that legacy mode, any entry that
# collides with a declarative entry is assumed to be ekaos-created and is
# replaced.

set -euo pipefail

if [ "$#" -ne 2 ]; then
  echo "usage: $0 <static-dir> <dest-dir>" >&2
  exit 2
fi

static=$1
dest=$2
marker="$dest/.ekaos-managed"

mkdir -p "$dest"

legacy=0
[ -e "$marker" ] || legacy=1

is_managed() {
  local target
  target=$(readlink "$1") || return 1
  case "$target" in
    "$static"/*) return 0 ;;
  esac
  return 1
}

# 1. Prune managed links whose declarative entry no longer exists, plus (in
#    legacy mode) links left by the old package-unit activation loop.
while IFS= read -r -d '' link; do
  target=$(readlink "$link")
  case "$target" in
    "$static"/*)
      if [ ! -e "$target" ] && [ ! -L "$target" ]; then
        rm -f "$link"
      fi
      ;;
    /etc/systemd/system-packages/* | /etc/systemd/user-packages/*)
      if [ "$legacy" = 1 ]; then
        rm -f "$link"
      fi
      ;;
  esac
done < <(find "$dest" -mindepth 1 -type l -print0)

# 2. Create or update a managed link for every declarative entry.
if [ -d "$static" ]; then
  while IFS= read -r -d '' entry; do
    rel=${entry#"$static"/}
    want="$static/$rel"
    path="$dest/$rel"

    if [ -L "$path" ] && [ "$(readlink "$path")" = "$want" ]; then
      continue
    fi

    if [ -e "$path" ] || [ -L "$path" ]; then
      if [ -L "$path" ] && [ "$(readlink "$path")" = /dev/null ]; then
        # `systemctl mask` — an explicit administrator decision
        continue
      elif is_managed "$path" || [ "$legacy" = 1 ]; then
        rm -rf "$path"
      else
        echo "ekaos: not replacing administrator-managed $path" >&2
        continue
      fi
    fi

    mkdir -p "${path%/*}"
    ln -s "$want" "$path"
  done < <(find -H "$static" -mindepth 1 ! -type d -print0)
fi

# 3. Drop enablement and drop-in directories emptied by pruning.
find "$dest" -mindepth 1 -depth -type d \
  \( -name '*.wants' -o -name '*.requires' -o -name '*.d' \) -empty -delete

if [ "$legacy" = 1 ]; then
  # Regular files cannot be attributed: they may be stale copies from the old
  # `cp -rfL` activation or units written by the administrator. Leave them
  # in place but make them visible.
  stale=$(find "$dest" -mindepth 1 -type f ! -name '.ekaos-managed' | wc -l)
  if [ "$stale" -gt 0 ]; then
    echo "ekaos: $dest contains $stale unmanaged regular file(s);" \
      "remove any left over from previous generations by hand" >&2
  fi
  : >"$marker"
fi
