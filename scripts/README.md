# Scripts

Tooling for maintaining corepkgs. Every script uses a `nix-shell` or `env`
shebang and is meant to be run from the repository root:

```bash
./scripts/<name>
```

| Script | Purpose |
| --- | --- |
| [`freeze-release/freeze-release.sh`](#freeze-release) | Pin every `pkgs-many/` package to its default variant as an overlay |
| [`sync-with-nixpkgs/sync.py`](#sync-with-nixpkgs) | Report how corepkgs diverges from a nixpkgs checkout |
| [`repology/generate.sh`](#repology) | Produce a Repology-compatible `packages.json` metadata dump |
| [`bootstrap-files/upload-bootstrap.sh`](bootstrap-files/README.md) | Upload stdenv bootstrap tarballs |
| `ci-jobs.nix` | Job-set entry point (`import ../. { }`) |

## freeze-release

Creates "stable releases" by generating a Nix overlay that pins each package in
`pkgs-many/` to its current default variant. This ensures that the major
versions of software don't change over time, providing a stable baseline for
deployments.

- `freeze-release/freeze-release.sh` - shell wrapper for easy usage
- `freeze-release/freeze-release.nix` - core Nix script that does the actual work

Requires Nix, Git (for commit metadata), and Bash.

### Usage

```bash
# Generate a frozen release with default settings
./scripts/freeze-release/freeze-release.sh

# Specify a custom release name
./scripts/freeze-release/freeze-release.sh "stable-2026.1"

# Specify both release name and output path
./scripts/freeze-release/freeze-release.sh "stable-2026.1" "./overlays/stable-2026.1.nix"
```

You can also call the Nix script directly for more control:

```bash
nix-build scripts/freeze-release/freeze-release.nix \
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
   ./scripts/freeze-release/freeze-release.sh "stable-2026.Q2" "./overlays/stable-2026-q2.nix"
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

## sync-with-nixpkgs

Reports how corepkgs diverges from a nixpkgs checkout, one patch per package.
Full documentation lives in
[`sync-with-nixpkgs/README.md`](sync-with-nixpkgs/README.md).

```bash
# write patches and report drift against the accepted baseline
./scripts/sync-with-nixpkgs/sync.py --nixpkgs ../nixpkgs generate

# record divergence as intentional so it stops being reported
./scripts/sync-with-nixpkgs/sync.py --nixpkgs ../nixpkgs accept pkgs/curl.patch
```

- `patches/` holds every current divergence and is rewritten on each run
- `.sync-accepted/` holds divergence you have accepted
- both are gitignored: they are a local review aid, not repo content
- `--strict` exits non-zero when unaccepted drift exists, for use as a check

Only the nixpkgs side is transformed, so the diff's old side is the real file
and every patch applies from the repository root with `git apply -p1`. `.patch`
and `.diff` files are never diffed; a differing one is replaced by a note naming
both paths.

### Tests

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
