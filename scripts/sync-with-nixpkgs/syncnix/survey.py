"""Walking the two trees and turning them into patches.

This is the only module that reads the filesystem. It collects corepkgs files,
pairs each with its nixpkgs counterpart, and hands the text to `diffing`.
"""

import os
from collections import defaultdict
from dataclasses import dataclass, field
from pathlib import Path
from typing import Optional

from . import aliases, diffing, normalize, paths


@dataclass
class Survey:
    """The result of comparing the two trees."""

    patches: dict[str, str] = field(default_factory=dict)
    """Generated patch text, keyed by PATCHES_DIR-relative target."""

    identical: int = 0
    """Files that match upstream once normalised."""

    missing: list[str] = field(default_factory=list)
    """Mapped files with no counterpart in the nixpkgs checkout."""

    unmapped: list[str] = field(default_factory=list)
    """Files no PATH_MAPPINGS entry covers."""

    opaque_differs: list[str] = field(default_factory=list)
    """Patch files that differ from upstream and were noted, not diffed."""


def collect(root: Path) -> list[str]:
    """Every comparable file under `root`, as sorted relative paths.

    Ignored directories are pruned during the walk rather than filtered
    afterwards, so a large excluded tree is never descended into.
    """
    found: list[str] = []
    for current, directories, filenames in os.walk(root):
        relative = os.path.relpath(current, root)
        prefix = "" if relative == "." else relative

        directories[:] = [
            name
            for name in directories
            if not name.startswith(".")
            and not paths.is_ignored(os.path.join(prefix, name) if prefix else name)
        ]

        for filename in filenames:
            if filename.startswith("."):
                continue
            path = os.path.join(prefix, filename) if prefix else filename
            if not paths.is_ignored(path):
                found.append(path)
    return sorted(found)


def _read(path: Path) -> Optional[str]:
    try:
        return path.read_text(encoding="utf-8", errors="replace")
    except OSError:
        return None


def _compare_one(
    path: str,
    corepkgs_root: Path,
    nixpkgs_root: Path,
    survey: Survey,
    vocabulary: normalize.Vocabulary,
) -> Optional[diffing.Comparison]:
    """Compare a single file, recording why it was skipped when it was."""
    upstream_path = paths.resolve(path)
    if upstream_path is None:
        survey.unmapped.append(path)
        return None

    upstream_file = nixpkgs_root / upstream_path
    if not upstream_file.is_file():
        survey.missing.append(path)
        return None

    local_file = corepkgs_root / path
    local_text = _read(local_file)
    upstream_text = _read(upstream_file)
    if local_text is None or upstream_text is None:
        survey.missing.append(path)
        return None

    if paths.is_opaque(path):
        differs = local_text != upstream_text
        if differs:
            survey.opaque_differs.append(path)
        return diffing.compare_opaque(path, upstream_path, differs)

    return diffing.compare(path, upstream_path, local_text, upstream_text, vocabulary)


def run(corepkgs_root: Path, nixpkgs_root: Path) -> Survey:
    """Compare both trees and build one patch per target."""
    survey = Survey()
    grouped: dict[str, list[diffing.Comparison]] = defaultdict(list)
    vocabulary = aliases.load(corepkgs_root)

    for path in collect(corepkgs_root):
        comparison = _compare_one(path, corepkgs_root, nixpkgs_root, survey, vocabulary)
        if comparison is None:
            continue
        if comparison.diff is None and not comparison.opaque:
            survey.identical += 1
        grouped[paths.patch_target(path)].append(comparison)

    for target, comparisons in grouped.items():
        patch = diffing.render(target, comparisons)
        if patch is not None:
            survey.patches[target] = patch

    return survey
