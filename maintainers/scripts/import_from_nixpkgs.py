#!/usr/bin/env nix-shell
#!nix-shell -p python3 -i python3
from __future__ import annotations

import argparse
import shutil
import sys
from pathlib import Path


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            "Copy one or more package directories from ../nixpkgs into this repository. "
            "By default copies pkgs/by-name/<xx>/<name> -> pkgs/<name>. "
            "With --python, copies pkgs/development/python-modules/<name> -> python/pkgs/<name>."
        )
    )
    parser.add_argument(
        "--name",
        required=True,
        nargs="+",
        help="Package name(s) to import (used to locate source and destination directories).",
    )
    parser.add_argument(
        "--python",
        action="store_true",
        help="Import from pkgs/development/python-modules/<name> into python/pkgs/<name>.",
    )
    parser.add_argument(
        "--nixpkgs-root",
        type=Path,
        default=None,
        help="Override path to the nixpkgs checkout (default: ../nixpkgs relative to this script).",
    )
    parser.add_argument(
        "--force",
        action="store_true",
        help="Overwrite the destination directory if it already exists.",
    )
    return parser.parse_args()


def resolve_paths(args: argparse.Namespace, name: str) -> tuple[Path, Path]:
    # This script lives in maintainers/scripts/, so go up two levels to reach repo root.
    repo_root = Path(__file__).resolve().parents[2]
    nixpkgs_root = (
        args.nixpkgs_root.resolve()
        if args.nixpkgs_root
        else (repo_root / ".." / "nixpkgs").resolve()
    )

    if args.python:
        src = nixpkgs_root / "pkgs" / "development" / "python-modules" / name
        dest = repo_root / "python" / "pkgs" / name
    else:
        prefix = name[:2]
        src = nixpkgs_root / "pkgs" / "by-name" / prefix / name
        dest = repo_root / "pkgs" / name

    return src, dest


def copy_tree(src: Path, dest: Path, force: bool) -> None:
    if not src.exists():
        sys.exit(f"Source path does not exist: {src}")
    if not src.is_dir():
        sys.exit(f"Source path is not a directory: {src}")

    if dest.exists():
        if force:
            shutil.rmtree(dest)
        else:
            sys.exit(f"Destination already exists (use --force to overwrite): {dest}")

    dest.parent.mkdir(parents=True, exist_ok=True)
    # Copy the directory contents, keeping symlinks intact.
    shutil.copytree(src, dest, symlinks=True)


def rename_package_nix(dest: Path) -> None:
    """Rename package.nix to default.nix when present."""
    package_nix = dest / "package.nix"
    if not package_nix.exists():
        return

    default_nix = dest / "default.nix"
    if default_nix.exists():
        print(f"Note: both package.nix and default.nix exist in {dest}; leaving as-is.")
        return

    package_nix.rename(default_nix)
    print(f"Renamed {package_nix} -> {default_nix}")


def main() -> None:
    args = parse_args()
    for name in args.name:
        src, dest = resolve_paths(args, name)
        copy_tree(src, dest, args.force)
        rename_package_nix(dest)
        print(f"Imported {src} -> {dest}")


if __name__ == "__main__":
    main()

