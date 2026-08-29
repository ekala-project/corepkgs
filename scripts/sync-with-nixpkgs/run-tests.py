#!/usr/bin/env nix-shell
#!nix-shell -p "python3.withPackages (p: with p; [ pytest ])" -i python3
"""Run all tests for the sync-with-nixpkgs script."""

import subprocess
import sys
from pathlib import Path

if __name__ == "__main__":
    # Run pytest with verbose output
    result = subprocess.run(
        ["pytest", "-v", "--tb=short", "tests/"],
        cwd=Path(__file__).parent,
    )
    sys.exit(result.returncode)

