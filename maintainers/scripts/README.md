# Maintainer Scripts

This directory contains scripts used for maintaining corepkgs.

## sync-with-nixpkgs.py

Generates per-file patches between corepkgs and nixpkgs, handling directory structure differences.

### Usage

```bash
# From corepkgs root directory
python3 maintainers/scripts/sync-with-nixpkgs/sync-with-nixpkgs.py

# With custom paths
python3 maintainers/scripts/sync-with-nixpkgs/sync-with-nixpkgs.py --nixpkgs /path/to/nixpkgs --corepkgs /path/to/corepkgs
```

### Features

- Maps corepkgs directory structure to nixpkgs structure using PATH_MAPPINGS
- Generates directory-level patch files for differences
- Detects new files in monitored directories
- Handles special cases like `pkgs/by-name` structure
- Ignores specified directories and files

### Configuration

The script uses several configuration constants:

- `CHECK_NEW_FILES_DIRS`: Directories to monitor for new files and directories
- `CHECK_NEW_FILES_IGNORE_NEW_DIRS`: Subdirectories to ignore when checking for new files
- `IGNORE_DIRS`: Directories to ignore completely
- `IGNORE_FILES`: Files to ignore
- `PATH_MAPPINGS`: Maps corepkgs paths to nixpkgs paths

### Output

- Patch files are generated in the `patches/` directory
- An `index.txt` file is created listing all patches and statistics

## Tests

The test file uses nix-shell to provide Python and pytest. Run tests directly:

```bash
./maintainers/scripts/sync-with-nixpkgs/test_sync_with_nixpkgs.py
```
