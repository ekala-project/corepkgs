#!/usr/bin/env bash
# Generate a Repology-compatible packages.json metadata dump.
#
# Usage:
#   ./maintainers/scripts/repology/generate.sh [--compress] [--output DIR]
#
# Options:
#   --compress    Also produce a brotli-compressed .json.br file
#   --output DIR  Write output to DIR (default: current directory)
#   --system SYS  Target system (default: x86_64-linux)
#   --jobs N      Parallel evaluation jobs (default: number of CPUs)
#
# Requirements:
#   - nix (with nix-instantiate)
#   - jq
#   - brotli (only if --compress is used)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
OUTPUT_DIR="."
COMPRESS=false
SYSTEM="${SYSTEM:-x86_64-linux}"
JOBS="$(nproc 2>/dev/null || echo 4)"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --compress)
            COMPRESS=true
            shift
            ;;
        --output)
            OUTPUT_DIR="$2"
            shift 2
            ;;
        --system)
            SYSTEM="$2"
            shift 2
            ;;
        --jobs)
            JOBS="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1" >&2
            exit 1
            ;;
    esac
done

mkdir -p "$OUTPUT_DIR"

TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

# Discover package names from the pkgs/ directory structure.
echo "Discovering packages..." >&2
find "$REPO_ROOT/pkgs" -maxdepth 2 -name default.nix -printf '%h\n' \
    | xargs -n1 basename \
    | sort \
    > "$TMPDIR/package-names.txt"

pkg_count=$(wc -l < "$TMPDIR/package-names.txt")
echo "Found $pkg_count package directories" >&2
echo "Evaluating package metadata for $SYSTEM (jobs=$JOBS)..." >&2

mkdir -p "$TMPDIR/results"

# Evaluate each package individually so that abort failures in one
# package don't prevent the rest from being evaluated.
eval_package() {
    local name="$1"
    local outfile="$TMPDIR/results/$name.json"

    local result
    if result=$(nix-instantiate --eval --strict --json \
        --arg system "\"$SYSTEM\"" \
        --arg attrName "\"$name\"" \
        "$SCRIPT_DIR/packages-info.nix" 2>/dev/null); then
        if [[ "$result" != "null" ]]; then
            echo "$result" > "$outfile"
        fi
    fi
}

export -f eval_package
export TMPDIR SYSTEM SCRIPT_DIR

xargs -P "$JOBS" -I{} bash -c 'eval_package "$@"' _ {} < "$TMPDIR/package-names.txt"

# Merge all individual results into the final packages.json.
echo "Merging results..." >&2

{
    echo '{"version":"2","packages":{'
    first=true
    for f in "$TMPDIR"/results/*.json; do
        [[ -f "$f" ]] || continue
        name="$(basename "$f" .json)"
        if [[ "$first" == true ]]; then
            first=false
        else
            echo ','
        fi
        printf '"%s":' "$name"
        cat "$f"
    done
    echo '}}'
} | jq -c '.' > "$OUTPUT_DIR/packages.json"

PKG_COUNT=$(jq '.packages | length' < "$OUTPUT_DIR/packages.json")
echo "Generated metadata for $PKG_COUNT packages -> $OUTPUT_DIR/packages.json" >&2

if [[ "$PKG_COUNT" -lt 10 ]]; then
    echo "WARNING: Only $PKG_COUNT packages found, something may be wrong." >&2
    exit 1
fi

if [[ "$COMPRESS" == true ]]; then
    if ! command -v brotli &>/dev/null; then
        echo "ERROR: brotli not found. Install it or remove --compress." >&2
        exit 1
    fi
    brotli -9 --force < "$OUTPUT_DIR/packages.json" > "$OUTPUT_DIR/packages.json.br"
    echo "Compressed -> $OUTPUT_DIR/packages.json.br" >&2
fi

echo "Done." >&2
