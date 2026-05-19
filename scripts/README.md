# Freeze Release Script

This directory contains scripts for creating frozen release overlays from `pkgs-many/` packages.

## Overview

The freeze-release script creates "stable releases" by generating a Nix overlay that pins each package in `pkgs-many/` to its current default variant. This ensures that the major versions of software don't change over time, providing a stable baseline for deployments.

## Usage

### Basic Usage

```bash
# Generate a frozen release with default settings
./scripts/freeze-release.sh

# Specify a custom release name
./scripts/freeze-release.sh "stable-2026.1"

# Specify both release name and output path
./scripts/freeze-release.sh "stable-2026.1" "./overlays/stable-2026.1.nix"
```

### Using the Generated Overlay

Once you've generated a frozen release overlay, you can use it in several ways:

#### Method 1: Command-line usage

```bash
# Build a package using the frozen overlay
nix-build -E '(import ./. { overlays = [ (import ./overlays/stable-2026.1.nix) ]; }).nodejs'
```

#### Method 2: In your Nix configuration

```nix
# In your configuration.nix or similar
{
  nixpkgs.overlays = [
    (import /path/to/core-pkgs/overlays/stable-2026.1.nix)
  ];
}
```

#### Method 3: When importing core-pkgs

```nix
# In your project's default.nix
let
  pkgs = import /path/to/core-pkgs {
    overlays = [
      (import /path/to/core-pkgs/overlays/stable-2026.1.nix)
    ];
  };
in
pkgs
```

## How It Works

1. **Enumeration**: The script scans all packages in `pkgs-many/`
2. **Detection**: For each package, it reads the `default.nix` file and parses the `defaultSelector` to determine which variant is currently the default
3. **Generation**: It creates an overlay file that pins each package to its default variant using syntax like:
   ```nix
   nodejs = prev.nodejs.v22;
   go = prev.go.v1_25;
   ```
4. **Metadata**: The overlay includes metadata (release name, timestamp, git commit) for traceability

## Example Output

A generated frozen release overlay looks like this:

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

## Files

- `freeze-release.sh` - Shell wrapper script for easy usage
- `freeze-release.nix` - Core Nix script that does the actual work
- `README.md` - This file

## Requirements

- Nix package manager
- Git (for commit metadata)
- Bash (for the wrapper script)

## Advanced Usage

### Direct Nix Script Usage

You can also call the Nix script directly for more control:

```bash
nix-build scripts/freeze-release.nix \
  --argstr releaseName "stable-2026.1" \
  --argstr outputPath "./overlays/stable-2026.1.nix" \
  --argstr corePkgsPath "/path/to/core-pkgs" \
  --argstr gitCommit "abc123" \
  --argstr timestamp "2026-05-18T12:00:00Z"
```

### Verifying the Frozen Versions

To check which version a package is frozen to:

```bash
# Check nodejs version
nix-instantiate --eval -E '(import ./. { overlays = [ (import ./overlays/stable-2026.1.nix) ]; }).nodejs.version'

# Check go version
nix-instantiate --eval -E '(import ./. { overlays = [ (import ./overlays/stable-2026.1.nix) ]; }).go.version'
```

## Release Strategy

### Recommended Workflow

1. **Create a new frozen release** when you want to establish a new stable baseline:
   ```bash
   ./scripts/freeze-release.sh "stable-2026.Q2" "./overlays/stable-2026-q2.nix"
   ```

2. **Commit the overlay** to version control:
   ```bash
   git add overlays/stable-2026-q2.nix
   git commit -m "Add stable-2026.Q2 frozen release"
   ```

3. **Use the frozen release** in production environments to ensure version stability

4. **Update the release** periodically (e.g., quarterly) by generating a new overlay:
   ```bash
   ./scripts/freeze-release.sh "stable-2026.Q3" "./overlays/stable-2026-q3.nix"
   ```

### Naming Conventions

Consider using semantic naming for your releases:

- `stable-YYYY.Q#` - Quarterly releases (e.g., `stable-2026.Q2`)
- `stable-YYYY.MM` - Monthly releases (e.g., `stable-2026.05`)
- `lts-vX.Y` - Long-term support releases (e.g., `lts-v1.0`)
- Custom names for special releases (e.g., `production-v1`, `legacy-support`)

## Troubleshooting

### Package Not Included in Overlay

If a package from `pkgs-many/` is missing from the generated overlay:

1. Check that the package has a `default.nix` and `variants.nix` file
2. Verify that the `defaultSelector` in `default.nix` follows the standard pattern: `defaultSelector = (p: p.vXX);`
3. The script uses regex pattern matching, so non-standard formats may not be detected

### Overlay Not Working

If the overlay doesn't work when applied:

1. Verify the syntax is correct (should be `final: prev: { ... }`)
2. Check that the variant names match what's available in the package
3. Ensure you're using a compatible version of core-pkgs

## Contributing

To improve the freeze-release script:

- Extend the regex pattern in `parseDefaultSelector` to handle more `defaultSelector` formats
- Add support for additional metadata or documentation generation
- Improve error handling and reporting

## License

This script is part of the core-pkgs project and follows the same license.
