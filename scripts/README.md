# Scripts

Tooling for maintaining corepkgs. Every script uses a `nix-shell` or `env`
shebang and is meant to be run from the repository root:

```bash
./scripts/<name>
```

| Script | Purpose |
| --- | --- |
| [`freeze-release.sh`](#freeze-release) | Pin every `pkgs-many/` package to its default variant as an overlay |
| [`import-from-nixpkgs.py`](#import-from-nixpkgs) | Copy package directories out of a nixpkgs checkout |
| [`sync-with-nixpkgs/sync.py`](#sync-with-nixpkgs) | Generate per-file patches between corepkgs and nixpkgs |
| [`repology/generate.sh`](#repology) | Produce a Repology-compatible `packages.json` metadata dump |
| [`bootstrap-files/upload-bootstrap.sh`](bootstrap-files/README.md) | Upload stdenv bootstrap tarballs |
| `ci-jobs.nix` | Job-set entry point (`import ../. { }`) |

## freeze-release

Creates "stable releases" by generating a Nix overlay that pins each package in
`pkgs-many/` to its current default variant. This ensures that the major
versions of software don't change over time, providing a stable baseline for
deployments.

- `freeze-release.sh` - shell wrapper for easy usage
- `freeze-release.nix` - core Nix script that does the actual work

Requires Nix, Git (for commit metadata), and Bash.

### Usage

```bash
# Generate a frozen release with default settings
./scripts/freeze-release.sh

# Specify a custom release name
./scripts/freeze-release.sh "stable-2026.1"

# Specify both release name and output path
./scripts/freeze-release.sh "stable-2026.1" "./overlays/stable-2026.1.nix"
```

You can also call the Nix script directly for more control:

```bash
nix-build scripts/freeze-release.nix \
  --argstr releaseName "stable-2026.1" \
  --argstr outputPath "./overlays/stable-2026.1.nix" \
  --argstr corePkgsPath "/path/to/core-pkgs" \
  --argstr gitCommit "abc123" \
  --argstr timestamp "2026-05-18T12:00:00Z"
```

### How it works

1. **Enumeration**: scans all packages in `pkgs-many/`
2. **Detection**: for each package, reads `default.nix` and parses the
   `defaultSelector` to determine which variant is currently the default
3. **Generation**: creates an overlay file pinning each package to that variant
4. **Metadata**: the overlay records release name, timestamp, and git commit for
   traceability

A generated overlay looks like this:

```nix
# Frozen Release: stable-2026.1
# Generated: 2026-05-18T21:33:25Z
# From commit: 874b560
#
# This overlay freezes all pkgs-many/ packages to their default variants
# to create a stable release where major versions don't change over time.

final: prev: {
  abseil-cpp = prev.abseil-cpp.v202508;
  nodejs = prev.nodejs.v22;
  go = prev.go.v1_25;
  # ... (40+ packages total)
}
```

### Using the generated overlay

```bash
# Command line
nix-build -E '(import ./. { overlays = [ (import ./overlays/stable-2026.1.nix) ]; }).nodejs'
```

```nix
# In a NixOS configuration
{
  nixpkgs.overlays = [
    (import /path/to/core-pkgs/overlays/stable-2026.1.nix)
  ];
}
```

```nix
# When importing core-pkgs directly
let
  pkgs = import /path/to/core-pkgs {
    overlays = [
      (import /path/to/core-pkgs/overlays/stable-2026.1.nix)
    ];
  };
in
pkgs
```

To check which version a package is frozen to:

```bash
nix-instantiate --eval -E '(import ./. { overlays = [ (import ./overlays/stable-2026.1.nix) ]; }).nodejs.version'
```

### Release strategy

1. **Create a new frozen release** when establishing a new stable baseline:
   ```bash
   ./scripts/freeze-release.sh "stable-2026.Q2" "./overlays/stable-2026-q2.nix"
   ```
2. **Commit the overlay** to version control
3. **Use it** in production environments to ensure version stability
4. **Update it** periodically (e.g. quarterly) by generating a new overlay

Suggested naming: `stable-YYYY.Q#` (quarterly), `stable-YYYY.MM` (monthly),
`lts-vX.Y` (long-term support), or a custom name for special releases.

### Troubleshooting

**Package missing from the overlay:** check that it has both `default.nix` and
`variants.nix`, and that `defaultSelector` follows the standard pattern
`defaultSelector = (p: p.vXX);` — detection is regex-based, so non-standard
formats are not matched.

**Overlay not working:** verify the syntax is `final: prev: { ... }`, that the
variant names match what the package actually provides, and that the core-pkgs
version is compatible.

To improve the script, extend the regex in `parseDefaultSelector` to handle more
`defaultSelector` formats.

## import-from-nixpkgs

Copies one or more package directories from nixpkgs into corepkgs, handling
directory structure differences and file renames.

### Usage

```bash
# Import a package from pkgs/by-name/<xx>/<name> to pkgs/<name>
./scripts/import-from-nixpkgs.py --name <package-name>

# Import multiple packages
./scripts/import-from-nixpkgs.py --name <package1> <package2> <package3>

# Import a Python package from pkgs/development/python-modules/<name> to python/pkgs/<name>
./scripts/import-from-nixpkgs.py --name <package-name> --python

# Override nixpkgs root path (default: ../nixpkgs relative to the script)
./scripts/import-from-nixpkgs.py --name <package-name> --nixpkgs-root /path/to/nixpkgs

# Overwrite existing destination directory
./scripts/import-from-nixpkgs.py --name <package-name> --force
```

### Options

- `--name`: package name(s) to import (required, accepts multiple)
- `--python`: import from the Python modules directory instead of by-name
- `--nixpkgs-root`: override path to the nixpkgs checkout (default: `../nixpkgs`)
- `--force`: overwrite the destination if it already exists

### Features

- Automatically resolves source and destination paths based on package name
- Handles `pkgs/by-name/<prefix>/<name>` structure for regular packages
- Supports Python module imports from `pkgs/development/python-modules`
- Renames `package.nix` to `default.nix` when present
- Preserves symlinks during copy operations
- Validates source paths exist before copying

## sync-with-nixpkgs

Generates per-file patches between corepkgs and nixpkgs, handling directory
structure differences.

### Usage

```bash
# From the corepkgs root directory
./scripts/sync-with-nixpkgs/sync.py

# With custom paths
./scripts/sync-with-nixpkgs/sync.py --nixpkgs /path/to/nixpkgs --corepkgs /path/to/corepkgs
```

### Features

- Maps corepkgs directory structure to nixpkgs structure using PATH_MAPPINGS
- Generates directory-level patch files for differences
- Detects new files in monitored directories
- Handles special cases like `pkgs/by-name` structure
- Ignores specified directories and files
- Applies path transformations and filters to normalize differences

### Configuration

The script uses several configuration constants:

- `CHECK_NEW_FILES`: directories to monitor for new files and directories
- `IGNORE_NEW`: subdirectories to ignore when checking for new files
- `IGNORE_DIRS`: directories to ignore completely
- `IGNORE_FILES`: files to ignore
- `PATH_MAPPINGS`: maps corepkgs paths to nixpkgs paths
- `PATH_TRANSFORMATIONS`: regex patterns to transform nixpkgs paths in file content
- `PATTERN_ALIASES`: maps nixpkgs pattern names to corepkgs equivalents
- `IGNORE_CHANGE_PATTERNS`: patterns for changes to filter out from diffs
- `COREPKGS_SPECIFIC_PATTERNS`: patterns for corepkgs-specific lines to hide from diffs

### Output

- Patch files are generated in the `patches/` directory
- An `index.txt` file lists all patches and statistics

### Tests

The test suite uses nix-shell to provide Python and pytest:

```bash
./scripts/sync-with-nixpkgs/run-tests.py
```

## repology

Generates a Repology-compatible `packages.json` metadata dump.

```bash
./scripts/repology/generate.sh [--compress] [--output DIR]
```

- `--compress` also produces a brotli-compressed `.json.br` file
- `--output DIR` writes output to DIR (default: current directory)
- `--system SYS` targets a system (default: `x86_64-linux`)
- `--jobs N` sets parallel evaluation jobs (default: number of CPUs)

`packages-info.nix` evaluates a single package by attribute name and returns its
metadata; `generate.sh` calls it once per package and merges the results.
