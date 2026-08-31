#!/usr/bin/env nix-shell
#!nix-shell -p "python3.withPackages (p: with p; [ pytest ])" -i python3
"""Run the sync tool's test suite."""

import subprocess
import sys
from pathlib import Path

if __name__ == "__main__":
    sys.exit(
        subprocess.run(
            ["pytest", "-q", "--tb=short", "tests/"], cwd=Path(__file__).resolve().parent
        ).returncode
    )
