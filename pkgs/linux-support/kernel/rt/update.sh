#!/usr/bin/env bash
set -euo pipefail

# To update all rt kernels run: ./update.sh

# To update just one branch run: ./update.sh 5.15

# To add a new kernel branch 5.Y run: ./update.sh 5.Y
# (with the branch absent from kernels-rt.json) and update pkgs-many/linux.

# To commit run with: env COMMIT=1

mirror=https://kernel.org/pub/linux/kernel
versions=$(dirname "$0")/kernels-rt.json

main() {
    if [ $# -ge 1 ]; then
        update-if-needed "$1"
    else
        update-all-if-needed
    fi
}

branches() {
    python3 -c 'import json,sys; print(*json.load(open(sys.argv[1])))' "$versions"
}

update-all-if-needed() {
    for branch in $(branches); do
        update-if-needed "$branch"
    done
}

json-version() {
    branch="$1" # e.g. 5.15
    python3 -c 'import json,sys; print(json.load(open(sys.argv[1])).get(sys.argv[2], {}).get("version", ""))' \
        "$versions" "$branch"
}

latest-rt-version() {
    branch="$1" # e.g. 5.4
    curl -sL "$mirror/projects/rt/$branch/sha256sums.asc" |
        sed -ne '/.patch.xz/ { s/.*patch-\(.*\).patch.xz/\1/p}' |
        grep -v '\-rc' |
        sort --version-sort |
        tail -n 1
}

# Rewrite one branch's entry, keeping branches ordered newest first.
write-entry() {
    python3 - "$versions" "$1" "$2" "$3" "$4" <<'EOF'
import json
import sys

path, branch, version, khash, phash = sys.argv[1:]
with open(path) as handle:
    kernels = json.load(handle)
kernels[branch] = {"version": version, "hash": khash, "patchHash": phash}
kernels = dict(
    sorted(kernels.items(), key=lambda kv: [int(n) for n in kv[0].split(".")], reverse=True)
)
with open(path, "w") as handle:
    json.dump(kernels, handle, indent=4)
    handle.write("\n")
EOF
}

update-if-needed() {
    branch="$1" # e.g. 5.4 (added if not present)
    cur=$(json-version "$branch") # e.g. 5.4.59-rt36 or empty
    new=$(latest-rt-version "$branch") # e.g. 5.4.61-rt37
    kversion=${new%-*} # e.g. 5.4.61
    major=${branch%.*} # e.g 5
    nixattr="linux-rt_${branch/./_}"
    if [ "$new" = "$cur" ]; then
        echo "$nixattr: $cur (up-to-date)"
        return
    fi
    khash=$(nix-prefetch-url "$mirror/v${major}.x/linux-${kversion}.tar.xz" | nix-hash --type sha256 --to-sri)
    phash=$(nix-prefetch-url "$mirror/projects/rt/${branch}/older/patch-${new}.patch.xz" | nix-hash --type sha256 --to-sri)
    if [ "$cur" ]; then
        msg="$nixattr: $cur -> $new"
    else
        msg="$nixattr: init at $new"
    fi
    echo "$msg"
    write-entry "$branch" "$new" "$khash" "$phash"
    if [ "${COMMIT:-}" ]; then
        git add "$versions"
        git commit -m "$msg"
    fi
}

return 2>/dev/null || main "$@"
