#!/usr/bin/env bash
# Wrapper script to generate a frozen release overlay from pkgs-many/ packages
#
# Usage:
#   ./scripts/freeze-release.sh [RELEASE_NAME] [OUTPUT_PATH]
#
# Examples:
#   ./scripts/freeze-release.sh "stable-2026.1"
#   ./scripts/freeze-release.sh "stable-2026.1" "./overlays/frozen-2026.1.nix"
#   ./scripts/freeze-release.sh  # Uses defaults

set -euo pipefail

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CORE_PKGS_ROOT="$(dirname "$SCRIPT_DIR")"

# Default values
RELEASE_NAME="${1:-stable-$(date +%Y.%m)}"
OUTPUT_PATH="${2:-$CORE_PKGS_ROOT/overlays/frozen-release.nix}"

# Get git commit hash and timestamp
GIT_COMMIT=$(cd "$CORE_PKGS_ROOT" && git rev-parse --short HEAD 2>/dev/null || echo "unknown")
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

echo "=== Frozen Release Generator ==="
echo "Release name: $RELEASE_NAME"
echo "Output path:  $OUTPUT_PATH"
echo "Git commit:   $GIT_COMMIT"
echo "Timestamp:    $TIMESTAMP"
echo ""

# Create overlays directory if it doesn't exist
OUTPUT_DIR="$(dirname "$OUTPUT_PATH")"
mkdir -p "$OUTPUT_DIR"

# Run the Nix script to generate the overlay
echo "Generating frozen release overlay..."
nix-build "$SCRIPT_DIR/freeze-release.nix" \
  --argstr releaseName "$RELEASE_NAME" \
  --argstr outputPath "$OUTPUT_PATH" \
  --argstr corePkgsPath "$CORE_PKGS_ROOT" \
  --argstr gitCommit "$GIT_COMMIT" \
  --argstr timestamp "$TIMESTAMP" \
  -o /tmp/freeze-release-result \
  --show-trace

# Copy the generated file to the output path
GENERATED_FILE="/tmp/freeze-release-result/$(basename "$OUTPUT_PATH")"
if [ -f "$GENERATED_FILE" ]; then
  cp "$GENERATED_FILE" "$OUTPUT_PATH"
  echo ""
  echo "✓ Successfully generated frozen release overlay!"
  echo "  Output: $OUTPUT_PATH"
  echo ""
  echo "Usage:"
  echo "  nix-build -E '(import ./. { overlays = [ (import $OUTPUT_PATH) ]; }).nodejs'"
  echo ""

  # Show a preview of the overlay
  echo "Preview (first 20 lines):"
  head -20 "$OUTPUT_PATH"
  echo "..."
  echo ""
  echo "Total packages frozen: $(grep -c '= prev\.' "$OUTPUT_PATH" || echo "0")"
else
  echo "Error: Generated file not found at $GENERATED_FILE"
  exit 1
fi

# Clean up
rm -f /tmp/freeze-release-result
