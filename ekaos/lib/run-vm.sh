#!/usr/bin/env bash
# Wrapper script for running ekaos VMs
# Usage: run-vm.sh [configuration.nix]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EKAOS_DIR="$(dirname "$SCRIPT_DIR")"

CONFIG="${1:-$EKAOS_DIR/examples/minimal-system.nix}"

if [ ! -f "$CONFIG" ]; then
    echo "Error: Configuration file not found: $CONFIG"
    echo "Usage: $0 [configuration.nix]"
    exit 1
fi

echo "========================================="
echo "ekaos VM Runner"
echo "========================================="
echo "Configuration: $CONFIG"
echo ""

# Build the VM
echo "Building VM (this may take a while)..."
VM_RESULT=$(nix-build "$EKAOS_DIR" \
    --arg configuration "$CONFIG" \
    --argstr virtualisation.enable true \
    -A vm \
    --no-out-link)

if [ -z "$VM_RESULT" ]; then
    echo "Error: Failed to build VM"
    exit 1
fi

echo "VM built successfully: $VM_RESULT"
echo ""
echo "Starting VM..."
echo "Press Ctrl-C to stop"
echo "========================================="
echo ""

# Run the VM
exec "$VM_RESULT"
