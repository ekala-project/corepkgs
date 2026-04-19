#!/usr/bin/env bash
# Quick boot test script for ekaos
# Builds and boots the minimal test configuration

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EKAOS_DIR="$(dirname "$SCRIPT_DIR")"

echo "========================================="
echo "ekaos Quick Boot Test"
echo "========================================="
echo ""

# Build the boot test
echo "Building boot test..."
TEST_RESULT=$(nix-build "$SCRIPT_DIR/boot-test.nix" \
    --arg configuration "$SCRIPT_DIR/minimal-boot-test.nix" \
    -A test \
    --no-out-link)

if [ -z "$TEST_RESULT" ]; then
    echo "Error: Failed to build test"
    exit 1
fi

echo "Test built: $TEST_RESULT"
echo ""

# Run the test
echo "Running boot test..."
echo "(VM will run for 30 seconds to verify boot)"
echo ""

exec "$TEST_RESULT"
