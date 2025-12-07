#!/usr/bin/env nix-shell
#!nix-shell -p python3 -i python3
from __future__ import annotations

import argparse
import re
from pathlib import Path
from typing import Iterable

# Matches common maintainers assignments and replaces the whole assignment with `maintainers = [ ];`
# Handles forms like:
#   maintainers = [ foo bar ];
#   maintainers = with lib.maintainers; [ foo bar ];
MAINTAINERS_PATTERN = re.compile(
    r"(?ms)(?P<indent>^[ \t]*)maintainers\s*=\s*(?:with\s+[^\s;]+?\s*;\s*)?\[.*?\]\s*;"
)

# Matches `teams = [ ... ];` assignments (single or multi-line) and removes them.
# Restricts to array assignments to avoid false positives (e.g., functions or attrs).
TEAMS_PATTERN = re.compile(
    r"(?ms)^[ \t]*teams\s*=\s*(?:with\s+[^\s;]+?\s*;\s*)?\[.*?\]\s*;\s*\n?"
)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            "Sanitize maintainers and teams fields in Nix files. "
            "Replaces any maintainers assignment with an empty list and removes teams array assignments."
        )
    )
    parser.add_argument(
        "paths",
        nargs="*",
        default=["."],
        help="Files or directories to process (defaults to current directory).",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Show which files would change without writing them.",
    )
    parser.add_argument(
        "-v",
        "--verbose",
        action="store_true",
        help="Print per-file actions.",
    )
    return parser.parse_args()


def iter_nix_files(paths: Iterable[str]) -> list[Path]:
    seen: set[Path] = set()
    files: list[Path] = []
    for raw in paths:
        path = Path(raw)
        if path.is_dir():
            for f in sorted(path.rglob("*.nix")):
                if f not in seen:
                    seen.add(f)
                    files.append(f)
        elif path.is_file() and path.suffix == ".nix":
            if path not in seen:
                seen.add(path)
                files.append(path)
    return files


def sanitize_text(content: str) -> str:
    without_teams = TEAMS_PATTERN.sub("", content)
    sanitized = MAINTAINERS_PATTERN.sub(
        lambda m: f"{m.group('indent')}maintainers = [ ];", without_teams
    )
    return sanitized


def process_file(path: Path, dry_run: bool, verbose: bool) -> bool:
    original = path.read_text()
    updated = sanitize_text(original)
    changed = updated != original

    if changed:
        if dry_run:
            if verbose:
                print(f"[dry-run] would update {path}")
        else:
            path.write_text(updated)
            if verbose:
                print(f"[updated] {path}")
    else:
        if verbose:
            print(f"[unchanged] {path}")

    return changed


def main() -> None:
    args = parse_args()
    nix_files = iter_nix_files(args.paths)

    if not nix_files:
        print("No .nix files found to process.")
        return

    changed_count = sum(process_file(f, args.dry_run, args.verbose) for f in nix_files)
    print(f"Processed {len(nix_files)} files; changed {changed_count}.")


if __name__ == "__main__":
    main()

