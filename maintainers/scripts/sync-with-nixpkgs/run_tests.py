#!/usr/bin/env nix-shell
#!nix-shell -p "python3.withPackages (p: with p; [ pytest ])" -i python3
"""Run all tests for the sync-with-nixpkgs script."""

import sys
import subprocess

if __name__ == "__main__":
    # Run pytest with verbose output
    result = subprocess.run(
        ["pytest", "-v", "--tb=short", "tests/"],
        cwd="/home/qweered/Projects/corepkgs/maintainers/scripts/sync-with-nixpkgs"
    )
    sys.exit(result.returncode)

