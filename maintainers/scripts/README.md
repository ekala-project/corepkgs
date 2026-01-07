# Maintainer Scripts

This directory contains scripts used for maintaining corepkgs.

All scripts use nix-shell shebangs and can be executed directly with `./` from the repository root.

## sync-with-nixpkgs/script.py

Generates per-file patches between corepkgs and nixpkgs, handling directory structure differences.

### sync-with-nixpkgs Usage

```bash
# From corepkgs root directory
./maintainers/scripts/sync-with-nixpkgs/script.py

# With custom paths
./maintainers/scripts/sync-with-nixpkgs/script.py --nixpkgs /path/to/nixpkgs --corepkgs /path/to/corepkgs
```

### Features

- Maps corepkgs directory structure to nixpkgs structure using PATH_MAPPINGS
- Generates directory-level patch files for differences
- Detects new files in monitored directories
- Handles special cases like `pkgs/by-name` structure
- Ignores specified directories and files
- Applies path transformations and filters to normalize differences

### sync-with-nixpkgs Configuration

The script uses several configuration constants:

- `CHECK_NEW_FILES`: Directories to monitor for new files and directories
- `IGNORE_NEW`: Subdirectories to ignore when checking for new files
- `IGNORE_DIRS`: Directories to ignore completely
- `IGNORE_FILES`: Files to ignore
- `PATH_MAPPINGS`: Maps corepkgs paths to nixpkgs paths
- `PATH_TRANSFORMATIONS`: Regex patterns to transform nixpkgs paths in file content
- `PATTERN_ALIASES`: Maps nixpkgs pattern names to corepkgs equivalents
- `IGNORE_CHANGE_PATTERNS`: Patterns for changes to filter out from diffs
- `COREPKGS_SPECIFIC_PATTERNS`: Patterns for corepkgs-specific lines to hide from diffs

### Output

- Patch files are generated in the `patches/` directory
- An `index.txt` file is created listing all patches and statistics

### sync-with-nixpkgs Tests

The test suite uses nix-shell to provide Python and pytest. Run tests directly:

```bash
./maintainers/scripts/sync-with-nixpkgs/run_tests.py
```

## import_from_nixpkgs.py

Copies one or more package directories from nixpkgs into corepkgs, handling directory structure differences and file renames.

### import_from_nixpkgs Usage

```bash
# Import a package from pkgs/by-name/<xx>/<name> to pkgs/<name>
./maintainers/scripts/import_from_nixpkgs.py --name <package-name>

# Import multiple packages
./maintainers/scripts/import_from_nixpkgs.py --name <package1> <package2> <package3>

# Import a Python package from pkgs/development/python-modules/<name> to python/pkgs/<name>
./maintainers/scripts/import_from_nixpkgs.py --name <package-name> --python

# Override nixpkgs root path (default: ../nixpkgs relative to script)
./maintainers/scripts/import_from_nixpkgs.py --name <package-name> --nixpkgs-root /path/to/nixpkgs

# Overwrite existing destination directory
./maintainers/scripts/import_from_nixpkgs.py --name <package-name> --force
```

### import_from_nixpkgs Features

- Automatically resolves source and destination paths based on package name
- Handles `pkgs/by-name/<prefix>/<name>` structure for regular packages
- Supports Python module imports from `pkgs/development/python-modules`
- Renames `package.nix` to `default.nix` when present
- Preserves symlinks during copy operations
- Validates source paths exist before copying

### import_from_nixpkgs Options

- `--name`: Package name(s) to import (required, accepts multiple)
- `--python`: Import from Python modules directory instead of by-name
- `--nixpkgs-root`: Override path to nixpkgs checkout (default: `../nixpkgs`)
- `--force`: Overwrite destination if it already exists
