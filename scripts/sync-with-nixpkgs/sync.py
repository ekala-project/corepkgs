#!/usr/bin/env nix-shell
#!nix-shell -p "python3.withPackages (p: with p; [ ])" -i python3
"""Entry point for the nixpkgs sync. See `syncnix.cli` for the commands."""

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from syncnix import cli

if __name__ == "__main__":
    sys.exit(cli.main())
