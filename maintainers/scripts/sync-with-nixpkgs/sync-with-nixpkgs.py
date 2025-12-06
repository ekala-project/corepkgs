#!/usr/bin/env nix-shell
#!nix-shell -p "python3.withPackages (p: with p; [ ])" -i python3
"""Generate per-file patches between corepkgs and nixpkgs, handling directory structure differences."""

import argparse
import subprocess
import sys
from dataclasses import dataclass, field
from datetime import datetime
from pathlib import Path
from typing import Optional

CHECK_NEW_FILES = [
    "build-support",
    "common-updater",
    "os-specific",
    "stdenv",
    "systems",
    # "perl",
    # "python",
    # "pkgs",
    # "test",
]

CHECK_NEW_FILES_IGNORE_NEW_DIRS = [
    "build-support",
    "os-specific",
    "os-specific/linux",
]

IGNORE_DIRS = [
    "apparmor",      # TODO: Structure diverged upstream
    "docs",          # Documentation files
    "maintainers",   # Maintainer information
    "pkgs-many",     # Many packages directory
    "patches",       # Generated patch files directory
    "pkgs/rust",     # Synced 2025-12-05
    "stdenv/generic",# Synced 2025-12-06
]

IGNORE_FILES = [
    # Root level configuration files
    "README.md",
    "LICENSE",
    ".gitignore",
    "default.nix",
    "lib.nix",
    "pins.nix",
    "top-level.nix",
    "stdenv/aliases.nix",
    "stdenv/config.nix",
    "stdenv/generic/default.nix",
]

PATCHES_DIR = "patches"

PATH_MAPPINGS = {
    "build-support": "pkgs/build-support",
    "common-updater": "pkgs/common-updater",
    "os-specific": "pkgs/os-specific",
    "perl/buildperlpackage.nix": "pkgs/development/perl-modules/generic",
    "perl/perl-packages.nix": "pkgs/top-level/perl-packages.nix",
    "python": "pkgs/development/interpreters/python",
    "python/pkgs": "pkgs/development/python-modules",
    "pkgs": "pkgs/by-name",
    "pkgs/automake": "pkgs/development/tools/misc/automake",
    "pkgs/bash": "pkgs/shells/bash",
    "pkgs/binutils": "pkgs/development/tools/misc/binutils",
    "pkgs/boost": "pkgs/development/libraries/boost",
    "pkgs/dotnet": "pkgs/development/compilers/dotnet",
    "pkgs/gcc": "pkgs/development/compilers/gcc",
    "pkgs/glibc": "pkgs/development/libraries/glibc",
    "pkgs/gobject-introspection": "pkgs/development/libraries/gobject-introspection",
    "pkgs/llvm": "pkgs/development/compilers/llvm",
    "pkgs/openssh": "pkgs/tools/networking/openssh",
    "pkgs/rust": "pkgs/development/compilers/rust",
    "pkgs/systemd": "pkgs/os-specific/linux/systemd",
    "pkgs/texlive": "pkgs/tools/typesetting/tex/texlive",
    "pkgs/perl": "pkgs/development/interpreters/perl",
    "pkgs/xorg": "pkgs/servers/x11/xorg",
    "pkgs/javaPackages/openjdk": "pkgs/development/compilers/openjdk",
    "stdenv": "pkgs/stdenv",
    "stdenv/impure.nix": "pkgs/top-level/default.nix",
    "systems": "lib/systems",
    "test": "nixos/tests",
    "test/cc-wrapper": "pkgs/test/cc-wrapper",
    "test/haskell": "pkgs/test/haskell",
    "test/dotnet": "pkgs/test/dotnet",
    "test/stdenv": "pkgs/test/stdenv",
    "test/stdenv-inputs": "pkgs/test/stdenv-inputs",
    "test/make-binary-wrapper": "pkgs/test/make-binary-wrapper",
    "test/make-hardcode-gsettings-patch": "pkgs/test/make-hardcode-gsettings-patch",
    "release.nix": "pkgs/top-level/release.nix",
    "unixtools.nix": "pkgs/top-level/unixtools.nix",
}


@dataclass
class DiffStats:
    processed: int = 0
    found: int = 0
    different: int = 0
    ignored: int = 0
    not_found: int = 0
    not_found_list: list[str] = field(default_factory=list)
    new_files: int = 0
    new_files_list: list[str] = field(default_factory=list)
    # Track directories with differences for patch generation
    directories_with_diffs: dict[str, list[tuple[str, Path, Path]]] = field(default_factory=dict)


def should_ignore(rel_path: str) -> bool:
    """Check if a file or directory should be ignored."""
    return (any(rel_path.startswith(f"{d}/") or rel_path == d for d in IGNORE_DIRS) or
            Path(rel_path).name in IGNORE_FILES)


def should_ignore_new_files_dir(core_dir: str, subdir_name: str) -> bool:
    """Check if a subdirectory should be ignored when checking for new files."""
    rel_path = f"{core_dir}/{subdir_name}"
    return (any(subdir_name == p if "/" not in p else (rel_path == p or rel_path.startswith(f"{p}/"))
                for p in CHECK_NEW_FILES_IGNORE_NEW_DIRS) or
            any(rel_path.startswith(f"{d}/") or rel_path == d for d in IGNORE_DIRS))


def map_path_using_mappings(path: str, nixpkgs: Path, check_file: bool = True) -> Optional[Path]:
    """Map corepkgs path to nixpkgs path using PATH_MAPPINGS."""
    for core_prefix, nix_prefix in PATH_MAPPINGS.items():
        if path == core_prefix or path.startswith(f"{core_prefix}/"):
            mapped = nixpkgs / nix_prefix / path[len(core_prefix):].lstrip("/")
            if not check_file or mapped.is_file():
                return mapped
    return None


def map_path(rel_path: str, nixpkgs: Path) -> Optional[Path]:
    """Map corepkgs path to nixpkgs path."""
    if (exact := nixpkgs / rel_path).is_file():
        return exact
    if rel_path.startswith("pkgs/"):
        parts = rel_path[5:].split("/")
        if len(parts) == 2 and parts[1] == "default.nix":
            by_name = nixpkgs / "pkgs" / "by-name" / parts[0][:2].lower() / parts[0] / "package.nix"
            if by_name.is_file():
                return by_name
        if (direct := nixpkgs / "pkgs" / rel_path[5:]).is_file():
            return direct
    return map_path_using_mappings(rel_path, nixpkgs, check_file=True)


def reverse_map_path(nixpkgs_rel_path: str, corepkgs: Path) -> Optional[str]:
    """Map nixpkgs path to corepkgs relative path."""
    if (corepkgs / nixpkgs_rel_path).is_file():
        return nixpkgs_rel_path
    for core_prefix, nix_prefix in PATH_MAPPINGS.items():
        if nixpkgs_rel_path == nix_prefix or nixpkgs_rel_path.startswith(f"{nix_prefix}/"):
            suffix = nixpkgs_rel_path[len(nix_prefix):].lstrip("/")
            if core_prefix == "pkgs" and nix_prefix == "pkgs/by-name" and suffix:
                parts = suffix.split("/")
                if len(parts) >= 3 and parts[2] == "package.nix":
                    mapped = corepkgs / "pkgs" / parts[1] / "default.nix"
                    if mapped.is_file():
                        return str(mapped.relative_to(corepkgs))
            mapped = corepkgs / core_prefix / suffix if suffix else corepkgs / core_prefix
            if mapped.is_file():
                return str(mapped.relative_to(corepkgs))
    return None


def files_identical(f1: Path, f2: Path) -> bool:
    try:
        return f1.read_bytes() == f2.read_bytes()
    except FileNotFoundError:
        return False


def get_directory_path(rel_path: str) -> str:
    """Get the directory path for a file path."""
    return "/".join(rel_path.split("/")[:-1]) if "/" in rel_path else "."


def map_directory_path(dir_path: str, nixpkgs: Path, files_in_dir: list[tuple[str, Path, Path]]) -> Optional[Path]:
    """Map corepkgs directory path to nixpkgs directory path."""
    if dir_path == ".":
        return files_in_dir[0][2].parent if files_in_dir and files_in_dir[0][2] is not None else None
    if mapped := map_path_using_mappings(dir_path, nixpkgs, check_file=False):
        if mapped.exists():
            return mapped
    if (direct := nixpkgs / dir_path).exists():
        return direct
    return files_in_dir[0][2].parent if files_in_dir and files_in_dir[0][2] is not None else None


def extract_relative_path(absolute_path: str, base_path: str) -> str:
    """Extract relative file path from absolute path."""
    return absolute_path[len(base_path):].lstrip("/") if absolute_path.startswith(base_path) else Path(absolute_path).name


def replace_diff_path(line: str, prefix: str, base_path: str, dir_path: str) -> str:
    """Replace absolute path in diff header line with relative path."""
    if " " not in line:
        return line
    parts = line.split(" ", 1)
    has_timestamp = "\t" in parts[1]
    abs_path = parts[1].split("\t")[0] if has_timestamp else parts[1].strip()
    rel_file = extract_relative_path(abs_path, base_path)
    full_path = rel_file if dir_path == "." else f"{dir_path}/{rel_file}"
    prefix_slash = prefix.replace(" a", " a/").replace(" b", " b/")
    return f"{prefix_slash}{full_path}\t{parts[1].split('\t', 1)[1]}" if has_timestamp else f"{prefix_slash}{full_path}\n"


def filter_maintainer_changes(diff_content: str) -> tuple[str, bool]:
    """Filter out maintainer-related changes from diff content.
    
    Strategy: Remove entire hunks that ONLY contain maintainer changes.
    This preserves hunk line counts and ensures valid patches.
    
    Returns:
        tuple: (filtered_diff_content, has_non_maintainer_changes)
    """
    if not diff_content:
        return diff_content, False
    
    lines = diff_content.splitlines(keepends=True)
    result_lines = []
    has_non_maintainer_changes = False
    
    i = 0
    while i < len(lines):
        line = lines[i]
        
        # Keep file headers
        if line.startswith("diff ") or line.startswith("---") or line.startswith("+++") or line.startswith("\\"):
            result_lines.append(line)
            i += 1
            continue
        
        # Process hunk markers
        if line.startswith("@@"):
            hunk_start = i
            hunk_lines = []
            i += 1
            
            # Collect all lines in this hunk
            change_lines = []
            while i < len(lines):
                hunk_line = lines[i]
                # Stop at next hunk or file boundary
                if hunk_line.startswith("@@") or hunk_line.startswith("diff ") or hunk_line.startswith("---"):
                    break
                hunk_lines.append(hunk_line)
                if hunk_line.startswith("+") or hunk_line.startswith("-"):
                    change_lines.append(hunk_line[1:].strip().lower())
                i += 1
            
            # Check if all changes are maintainer-related
            all_maintainer = True
            if change_lines:
                all_changes_text = " ".join(change_lines)
                if "maintainers" not in all_changes_text:
                    all_maintainer = False
                else:
                    # Check if there are non-maintainer changes
                    # Remove maintainer patterns and see if anything remains
                    test_text = all_changes_text
                    for pattern in ["maintainers", "with", "[", "]", "=", ";"]:
                        test_text = test_text.replace(pattern, "")
                    test_text = "".join(c for c in test_text if c.isalnum() or c.isspace())
                    if len(test_text.strip()) > 20:  # Significant non-maintainer content
                        all_maintainer = False
            
            # Keep hunk if it has non-maintainer changes
            if not all_maintainer or not change_lines:
                has_non_maintainer_changes = True
                result_lines.append(line)  # Add hunk marker
                result_lines.extend(hunk_lines)
            # else: skip entire hunk (maintainer-only)
        else:
            # Shouldn't happen, but keep it
            result_lines.append(line)
            i += 1
    
    filtered_content = "".join(result_lines)
    # Ensure patch ends with newline
    if filtered_content and not filtered_content.endswith("\n"):
        filtered_content += "\n"
    
    return filtered_content, has_non_maintainer_changes


def generate_directory_patch(
    dir_path: str,
    files_in_dir: list[tuple[str, Path, Path]],
    corepkgs: Path,
    nixpkgs: Path,
    patches_dir: Path,
) -> Optional[Path]:
    """Generate a patch file for an entire directory."""
    # Skip generating patches for root-level files
    if dir_path == ".":
        return None
    
    nixpkgs_dir = map_directory_path(dir_path, nixpkgs, files_in_dir)
    if not nixpkgs_dir:
        return None
    
    corepkgs_dir = corepkgs / dir_path
    
    # Validate that both paths exist and are directories before running diff
    if not corepkgs_dir.exists() or not corepkgs_dir.is_dir():
        return None
    if not nixpkgs_dir.exists() or not nixpkgs_dir.is_dir():
        return None
    
    result = subprocess.run(
        ["diff", "-urN", str(corepkgs_dir), str(nixpkgs_dir)],
        capture_output=True,
        text=True,
        errors='replace',
    )
    
    if result.returncode == 0 and not result.stdout:
        return None
    
    lines = result.stdout.splitlines(keepends=True)
    corepkgs_str, nixpkgs_str = str(corepkgs_dir) + "/", str(nixpkgs_dir) + "/"
    
    for i, line in enumerate(lines):
        if line.startswith("diff -urN"):
            lines[i] = f"diff -urN a/{dir_path} b/{dir_path}\n"
        elif line.startswith("---"):
            lines[i] = replace_diff_path(line, "--- a", corepkgs_str, dir_path)
        elif line.startswith("+++"):
            lines[i] = replace_diff_path(line, "+++ b", nixpkgs_str, dir_path)
    
    diff_content = "".join(lines)
    
    # Filter out maintainer changes from the diff
    filtered_diff, has_non_maintainer_changes = filter_maintainer_changes(diff_content)
    
    # Skip generating patches if there are no non-maintainer changes
    if not has_non_maintainer_changes:
        return None
    
    # Use the filtered diff (without maintainer changes)
    diff_content = filtered_diff
    
    patch_file = patches_dir / f"{'root' if dir_path == '.' else dir_path.replace('/', '_')}.patch"
    patch_file.parent.mkdir(parents=True, exist_ok=True)
    
    with open(patch_file, "w") as f:
        f.write(f"# Patch for directory: {dir_path}\n")
        f.write(f"# Source directory in nixpkgs: {nixpkgs_dir.relative_to(nixpkgs)}\n")
        f.write(f"# Generated: {datetime.now()}\n")
        f.write(f"# Files in directory: {len(files_in_dir)}\n")
        f.write(f"#\n# To apply from corepkgs root:\n#   patch -p1 < {patch_file.relative_to(patches_dir.parent)}\n#\n")
        f.write(diff_content)
        if not diff_content.endswith("\n"):
            f.write("\n")
        if result.stderr:
            f.write(result.stderr)
            if not result.stderr.endswith("\n"):
                f.write("\n")
    
    return patch_file


def write_index(patches_dir: Path, stats: DiffStats) -> None:
    """Write an index file listing all patches."""
    with open(patches_dir / "index.txt", "w") as f:
        f.write(f"# Patches generated between corepkgs and nixpkgs\n# Generated: {datetime.now()}\n#\n")
        f.write(f"# Summary:\n#   Total files processed: {stats.processed}\n")
        f.write(f"#   Files found in nixpkgs: {stats.found}\n#   Files with differences: {stats.different}\n")
        f.write(f"#   Files not found: {stats.not_found}\n#   New files found: {stats.new_files}\n")
        f.write(f"#   Files ignored: {stats.ignored}\n#\n# Patch files:\n")
        for patch_file in sorted(patches_dir.glob("*.patch")):
            f.write(f"#   {patch_file.name}\n")
        if stats.not_found_list:
            f.write(f"#\n# TODO: Files not found in nixpkgs (may need path mapping):\n")
            for nf in stats.not_found_list:
                f.write(f"#   {nf}\n")
            if stats.not_found > len(stats.not_found_list):
                f.write(f"#   ... and {stats.not_found - len(stats.not_found_list)} more\n")
        if stats.new_files_list:
            f.write(f"#\n# New files found in nixpkgs (will be added via patches):\n")
            for nf in stats.new_files_list:
                f.write(f"#   {nf}\n")
            if stats.new_files > len(stats.new_files_list):
                f.write(f"#   ... and {stats.new_files - len(stats.new_files_list)} more\n")


def check_new_files(corepkgs: Path, nixpkgs: Path, stats: DiffStats) -> None:
    """Check for new files in nixpkgs that don't exist in corepkgs.
    
    For directories in CHECK_NEW_FILES:
    - Checks for files directly in the top-level directory (one level only)
    - For existing subdirectories, checks recursively for new files
    """
    print(f"\nChecking for new files in monitored directories...", file=sys.stderr)
    
    def process_file(nixpkgs_file: Path, corepkgs_file: Path, corepkgs_rel_path: str) -> None:
        """Helper function to process a single file."""
        if should_ignore(corepkgs_rel_path) or corepkgs_file.exists():
            return
        stats.new_files += 1
        stats.new_files_list.append(corepkgs_rel_path)
        dir_path = get_directory_path(corepkgs_rel_path)
        stats.directories_with_diffs.setdefault(dir_path, []).append((corepkgs_rel_path, None, nixpkgs_file))
        print(f"  Found new file: {corepkgs_rel_path}", file=sys.stderr)
    
    def get_corepkgs_path(nixpkgs_file: Path, corepkgs_subdir: Path) -> Optional[str]:
        """Get corepkgs relative path for a nixpkgs file."""
        return (reverse_map_path(str(nixpkgs_file.relative_to(nixpkgs)), corepkgs) or
                str((corepkgs_subdir / nixpkgs_file.name).relative_to(corepkgs)))
    
    def check_directory_recursive(
        corepkgs_subdir: Path,
        nixpkgs_subdir: Path,
        base_core_dir: str,
        skip_direct_files: bool = False
    ) -> None:
        """Recursively check for new files in a directory."""
        if not nixpkgs_subdir.exists() or not nixpkgs_subdir.is_dir():
            return
        
        # Check files directly in this directory (unless skipped)
        if not skip_direct_files:
            for nixpkgs_file in nixpkgs_subdir.iterdir():
                if not nixpkgs_file.is_file() or ".git" in nixpkgs_file.parts:
                    continue
                if corepkgs_rel_path := get_corepkgs_path(nixpkgs_file, corepkgs_subdir):
                    process_file(nixpkgs_file, corepkgs / corepkgs_rel_path, corepkgs_rel_path)
        
        for nested_corepkgs_subdir in corepkgs_subdir.iterdir():
            if not nested_corepkgs_subdir.is_dir() or ".git" in nested_corepkgs_subdir.parts:
                continue
            nested_rel = str(nested_corepkgs_subdir.relative_to(corepkgs))
            nested_subdir = nested_rel[len(base_core_dir) + 1:] if nested_rel.startswith(f"{base_core_dir}/") else nested_corepkgs_subdir.name
            check_directory_recursive(
                nested_corepkgs_subdir,
                nixpkgs_subdir / nested_corepkgs_subdir.name,
                base_core_dir,
                skip_direct_files=should_ignore_new_files_dir(base_core_dir, nested_subdir)
            )
        
        if not skip_direct_files:
            for nested_nixpkgs_subdir in nixpkgs_subdir.iterdir():
                if not nested_nixpkgs_subdir.is_dir() or ".git" in nested_nixpkgs_subdir.parts:
                    continue
                nested_corepkgs_subdir = corepkgs_subdir / nested_nixpkgs_subdir.name
                if not nested_corepkgs_subdir.exists():
                    nested_corepkgs_subdir.mkdir(parents=True, exist_ok=True)
                    check_directory_recursive(nested_corepkgs_subdir, nested_nixpkgs_subdir, base_core_dir, skip_direct_files=False)
                    nested_corepkgs_subdir.rmdir()
    
    for core_dir in CHECK_NEW_FILES:
        # Only check directories that are in PATH_MAPPINGS
        if core_dir not in PATH_MAPPINGS:
            continue
        nixpkgs_dir = map_path_using_mappings(core_dir, nixpkgs, check_file=False)
        if not nixpkgs_dir or not nixpkgs_dir.is_dir():
            continue
        corepkgs_dir = corepkgs / core_dir
        if not corepkgs_dir.exists():
            continue
        
        # Check files directly in top-level directory (skip if directory is ignored)
        if core_dir not in CHECK_NEW_FILES_IGNORE_NEW_DIRS:
            for nixpkgs_file in nixpkgs_dir.iterdir():
                if nixpkgs_file.is_file() and ".git" not in nixpkgs_file.parts:
                    if corepkgs_rel_path := get_corepkgs_path(nixpkgs_file, corepkgs_dir):
                        process_file(nixpkgs_file, corepkgs / corepkgs_rel_path, corepkgs_rel_path)
        
        for corepkgs_subdir in corepkgs_dir.iterdir():
            if corepkgs_subdir.is_dir() and ".git" not in corepkgs_subdir.parts:
                check_directory_recursive(
                    corepkgs_subdir,
                    nixpkgs_dir / corepkgs_subdir.name,
                    core_dir,
                    skip_direct_files=should_ignore_new_files_dir(core_dir, corepkgs_subdir.name)
                )
        
        if core_dir not in CHECK_NEW_FILES_IGNORE_NEW_DIRS:
            for nixpkgs_subdir in nixpkgs_dir.iterdir():
                if nixpkgs_subdir.is_dir() and ".git" not in nixpkgs_subdir.parts:
                    corepkgs_subdir = corepkgs_dir / nixpkgs_subdir.name
                    if not corepkgs_subdir.exists():
                        corepkgs_subdir.mkdir(parents=True, exist_ok=True)
                        check_directory_recursive(corepkgs_subdir, nixpkgs_subdir, core_dir, skip_direct_files=False)
                        corepkgs_subdir.rmdir()


def process_files(corepkgs: Path, nixpkgs: Path, patches_dir: Path, stats: DiffStats) -> None:
    """Process all files and generate patches."""
    for file_path in corepkgs.rglob("*"):
        if not file_path.is_file() or ".git" in file_path.parts or "result" in str(file_path):
            continue
        rel_path = str(file_path.relative_to(corepkgs))
        if should_ignore(rel_path):
            stats.ignored += 1
            continue
        stats.processed += 1
        if nixpkgs_file := map_path(rel_path, nixpkgs):
            stats.found += 1
            if not files_identical(nixpkgs_file, file_path):
                stats.different += 1
                dir_path = get_directory_path(rel_path)
                stats.directories_with_diffs.setdefault(dir_path, []).append((rel_path, file_path, nixpkgs_file))
        else:
            stats.not_found += 1
            stats.not_found_list.append(rel_path)
        if stats.processed % 100 == 0:
            print(f"Processed {stats.processed} files, found {stats.found} matches, "
                  f"{stats.different} different, {stats.not_found} not found", file=sys.stderr)
    
    check_new_files(corepkgs, nixpkgs, stats)
    print(f"\nGenerating directory patches...", file=sys.stderr)
    for dir_path, files_in_dir in sorted(stats.directories_with_diffs.items()):
        if patch_file := generate_directory_patch(dir_path, files_in_dir, corepkgs, nixpkgs, patches_dir):
            print(f"Generated patch: {patch_file.relative_to(patches_dir.parent)} ({len(files_in_dir)} files)", file=sys.stderr)


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Generate per-file patches between corepkgs and nixpkgs",
        epilog="Examples:\n  %(prog)s\n  %(prog)s --nixpkgs /path/to/nixpkgs --corepkgs /path/to/corepkgs",
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    parser.add_argument(
        "--nixpkgs",
        type=Path,
        help="Path to nixpkgs repository (default: ../nixpkgs relative to corepkgs)",
    )
    parser.add_argument(
        "--corepkgs",
        type=Path,
        default=Path.cwd(),
        help="Path to corepkgs repository (default: current directory)",
    )
    args = parser.parse_args()

    corepkgs = args.corepkgs.resolve()
    nixpkgs = args.nixpkgs.resolve() if args.nixpkgs else (corepkgs.parent / "nixpkgs").resolve()

    patches_dir = corepkgs / PATCHES_DIR
    patches_dir.mkdir(exist_ok=True)
    
    stats = DiffStats()

    print(f"Processing files from {corepkgs}...\nComparing with {nixpkgs}...\nPatches will be saved to {patches_dir}...", file=sys.stderr)
    process_files(corepkgs, nixpkgs, patches_dir, stats)
    write_index(patches_dir, stats)
    print(f"\nPatch generation complete!\nPatches saved to: {patches_dir}\nIndex file: {patches_dir / 'index.txt'}", file=sys.stderr)
    if stats.not_found_list:
        print(f"\nNot-found files ({len(stats.not_found_list)}):", file=sys.stderr)
        for nf in sorted(stats.not_found_list):
            print(f"  {nf}", file=sys.stderr)
    if stats.new_files_list:
        print(f"\nNew files found ({len(stats.new_files_list)}):", file=sys.stderr)
        for nf in sorted(stats.new_files_list):
            print(f"  {nf}", file=sys.stderr)
    print(f"\nFiles processed: {stats.processed}, found: {stats.found}, "
          f"different: {stats.different}, not found: {stats.not_found}, new files: {stats.new_files}", file=sys.stderr)


if __name__ == "__main__":
    main()

