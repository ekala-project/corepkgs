#!/usr/bin/env bash
# Build bootstrap tools for specified targets, upload them as GitHub
# release assets, and update the corresponding .nix files.
#
# Usage:
#   ./upload-bootstrap.bash [--targets=TARGET,...] [--tag=TAG] [--dry-run]
#
# Examples:
#   # Build and upload for the current system:
#   ./upload-bootstrap.bash
#
#   # Build for specific targets:
#   ./upload-bootstrap.bash --targets=x86_64-unknown-linux-gnu,aarch64-unknown-linux-gnu
#
#   # Build all supported targets:
#   ./upload-bootstrap.bash --targets=all
#
#   # Dry run (build only, no upload):
#   ./upload-bootstrap.bash --dry-run
#
# Prerequisites:
#   - nix with flakes support
#   - gh (GitHub CLI), authenticated
#   - Write access to the GitHub repo (for creating releases)

set -euo pipefail

REPO="ekala-project/corepkgs"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
BOOTSTRAP_FILES_DIR="$REPO_ROOT/stdenv/linux/bootstrap-files"

# All supported native targets (built natively on the respective platform)
NATIVE_TARGETS=(
    x86_64-unknown-linux-gnu
    aarch64-unknown-linux-gnu
)

# Targets that can be cross-built from x86_64-linux
CROSS_TARGETS=(
    aarch64-unknown-linux-musl
    x86_64-unknown-linux-musl
    armv5tel-unknown-linux-gnueabi
    armv6l-unknown-linux-gnueabihf
    armv6l-unknown-linux-musleabihf
    armv7l-unknown-linux-gnueabihf
    mips64el-unknown-linux-gnuabi64
    mips64el-unknown-linux-gnuabin32
    mipsel-unknown-linux-gnu
    powerpc64-unknown-linux-gnuabielfv1
    powerpc64-unknown-linux-gnuabielfv2
    powerpc64le-unknown-linux-gnu
    riscv64-unknown-linux-gnu
    s390x-unknown-linux-gnu
    loongarch64-unknown-linux-gnu
    i686-unknown-linux-gnu
)

ALL_TARGETS=("${NATIVE_TARGETS[@]}" "${CROSS_TARGETS[@]}")

# Map target triple to the nix system string used for building
target_to_system() {
    local target="$1"
    case "$target" in
        x86_64-unknown-linux-*)    echo "x86_64-linux" ;;
        i686-unknown-linux-*)      echo "x86_64-linux" ;;  # cross-built
        aarch64-unknown-linux-gnu) echo "aarch64-linux" ;;
        aarch64-unknown-linux-musl) echo "x86_64-linux" ;; # cross-built
        *)                         echo "x86_64-linux" ;;   # cross-built
    esac
}

# Map target triple to the nix attribute for building
target_to_attr() {
    local target="$1"
    local system
    system="$(target_to_system "$target")"

    # For native targets, use freshBootstrapTools directly
    # For cross targets, use pkgsCross
    case "$target" in
        x86_64-unknown-linux-gnu)
            echo "freshBootstrapTools.build" ;;
        aarch64-unknown-linux-gnu)
            echo "freshBootstrapTools.build" ;;
        *)
            # Cross targets would need pkgsCross support
            # For now, only native targets are fully supported
            echo "" ;;
    esac
}

# Parse arguments
DRY_RUN=false
TAG=""
TARGETS=()

for arg in "$@"; do
    case "$arg" in
        --targets=*)
            IFS=',' read -ra TARGETS <<< "${arg#--targets=}"
            ;;
        --tag=*)
            TAG="${arg#--tag=}"
            ;;
        --dry-run)
            DRY_RUN=true
            ;;
        --help|-h)
            head -20 "$0" | tail -17 | sed 's/^# \?//'
            exit 0
            ;;
        *)
            echo "Unknown argument: $arg" >&2
            exit 1
            ;;
    esac
done

# Expand "all" target
if [[ "${TARGETS[*]:-}" == "all" ]]; then
    TARGETS=("${ALL_TARGETS[@]}")
fi

# Default: detect current system's target
if [[ ${#TARGETS[@]} -eq 0 ]]; then
    current_system="$(nix eval --raw --impure --expr 'builtins.currentSystem')"
    case "$current_system" in
        x86_64-linux)  TARGETS=(x86_64-unknown-linux-gnu) ;;
        aarch64-linux) TARGETS=(aarch64-unknown-linux-gnu) ;;
        *)
            echo "Cannot auto-detect target for system: $current_system" >&2
            echo "Please specify --targets=TARGET" >&2
            exit 1
            ;;
    esac
fi

# Default tag: bootstrap-YYYY-MM-DD
if [[ -z "$TAG" ]]; then
    TAG="bootstrap-$(date +%Y-%m-%d)"
fi

REVISION="$(git -C "$REPO_ROOT" rev-parse HEAD)"
SHORT_REV="$(git -C "$REPO_ROOT" rev-parse --short HEAD)"

echo "=== Bootstrap Tools Upload ==="
echo "Repository: $REPO"
echo "Tag:        $TAG"
echo "Revision:   $REVISION"
echo "Targets:    ${TARGETS[*]}"
echo "Dry run:    $DRY_RUN"
echo ""

# Staging directory for built artifacts
STAGING="$(mktemp -d)"
trap 'rm -rf "$STAGING"' EXIT

built_targets=()

for target in "${TARGETS[@]}"; do
    echo "--- Building: $target ---"

    attr="$(target_to_attr "$target")"
    if [[ -z "$attr" ]]; then
        echo "  SKIP: Cross-building for $target is not yet supported by this script."
        echo "  (Requires pkgsCross configuration)"
        continue
    fi

    system="$(target_to_system "$target")"

    # Build
    echo "  nix-build --arg system \"$system\" -A $attr"
    out="$(nix-build "$REPO_ROOT" --arg system "$system" -A "$attr" --no-out-link)"
    echo "  Built: $out"

    # Stage artifacts with target-prefixed names for the release
    target_dir="$STAGING/$target"
    mkdir -p "$target_dir"
    cp "$out/on-server/bootstrap-tools.tar.xz" "$target_dir/"
    cp "$out/on-server/busybox" "$target_dir/"

    # Compute hashes
    tools_hash="$(nix hash file --sri "$target_dir/bootstrap-tools.tar.xz")"
    busybox_hash="$(nix hash file --sri "$target_dir/busybox")"
    tools_size="$(stat -c%s "$target_dir/bootstrap-tools.tar.xz")"
    busybox_size="$(stat -c%s "$target_dir/busybox")"

    echo "  bootstrap-tools.tar.xz: $tools_hash ($(numfmt --to=iec "$tools_size"))"
    echo "  busybox:                $busybox_hash ($(numfmt --to=iec "$busybox_size"))"

    # Generate the updated .nix file
    nix_file="$BOOTSTRAP_FILES_DIR/$target.nix"
    cat > "$nix_file" <<EOF
# Autogenerated by maintainers/scripts/bootstrap-files/upload-bootstrap.bash as:
# \$ ./upload-bootstrap.bash --targets=$target
#
# Metadata:
# - corepkgs revision: $REVISION
# - build time: $(date -u '+%a, %d %b %Y %H:%M:%S %z')
{
  bootstrapTools = import <nix/fetchurl.nix> {
    url = "https://github.com/$REPO/releases/download/$TAG/$target-bootstrap-tools.tar.xz";
    hash = "$tools_hash";
  };
  busybox = import <nix/fetchurl.nix> {
    url = "https://github.com/$REPO/releases/download/$TAG/$target-busybox";
    hash = "$busybox_hash";
    executable = true;
  };
}
EOF

    echo "  Updated: $nix_file"
    built_targets+=("$target")
    echo ""
done

if [[ ${#built_targets[@]} -eq 0 ]]; then
    echo "No targets were built. Nothing to upload."
    exit 0
fi

if [[ "$DRY_RUN" == true ]]; then
    echo "=== Dry run complete ==="
    echo "Built targets: ${built_targets[*]}"
    echo "Artifacts staged in: $STAGING"
    echo "Updated .nix files in: $BOOTSTRAP_FILES_DIR"
    echo ""
    echo "To upload manually, create a GitHub release with tag '$TAG' and attach:"
    for target in "${built_targets[@]}"; do
        echo "  $STAGING/$target/bootstrap-tools.tar.xz  ->  $target-bootstrap-tools.tar.xz"
        echo "  $STAGING/$target/busybox                 ->  $target-busybox"
    done
    # Keep staging dir alive for manual inspection
    trap '' EXIT
    exit 0
fi

# Upload to GitHub
echo "=== Uploading to GitHub ==="

# Check gh auth
if ! gh auth status &>/dev/null; then
    echo "Error: Not authenticated with GitHub CLI." >&2
    echo "Run: gh auth login" >&2
    exit 1
fi

# Build release notes
release_notes="Bootstrap tools built from corepkgs revision \`$SHORT_REV\` ($REVISION).\n\n"
release_notes+="**Targets:**\n"
for target in "${built_targets[@]}"; do
    release_notes+="- \`$target\`\n"
done
release_notes+="\n**Build date:** $(date -u '+%Y-%m-%d %H:%M UTC')\n"

# Create the release (or use existing)
if gh release view "$TAG" --repo "$REPO" &>/dev/null; then
    echo "Release '$TAG' already exists, uploading additional assets..."
else
    echo "Creating release '$TAG'..."
    echo -e "$release_notes" | gh release create "$TAG" \
        --repo "$REPO" \
        --title "Bootstrap Tools $TAG" \
        --notes-file - \
        --latest=false
fi

# Upload assets
for target in "${built_targets[@]}"; do
    echo "  Uploading $target artifacts..."
    gh release upload "$TAG" \
        --repo "$REPO" \
        --clobber \
        "$STAGING/$target/bootstrap-tools.tar.xz#$target-bootstrap-tools.tar.xz" \
        "$STAGING/$target/busybox#$target-busybox"
done

echo ""
echo "=== Done ==="
echo "Release: https://github.com/$REPO/releases/tag/$TAG"
echo ""
echo "The .nix files in $BOOTSTRAP_FILES_DIR have been updated."
echo "Don't forget to commit and push the changes:"
echo "  git add stdenv/linux/bootstrap-files/"
echo "  git commit -m 'bootstrap-files: update for ${built_targets[*]}'"
