# Agent Guide for core-pkgs

This document provides guidelines for AI agents working with the core-pkgs repository. It covers packaging conventions, directory structure, and validation requirements.

## Package Organization

### Automatic Package Scope Registration

Packages in `pkgs/` and `pkgs-many/` are automatically added to the `pkgs.*` package scope based on their directory name.

#### `pkgs/` Directory

Individual packages are placed in `pkgs/<package-name>/default.nix`. The package is automatically available as `pkgs.<package-name>` without requiring an explicit entry in `top-level.nix`.

**Example:**
```
pkgs/
  libxslt/
    default.nix
    77-Use-a-dedicated-node-type-to-maintain-the-list-of-cached-rv-ts.patch
```

This package is automatically available as `pkgs.libxslt`.

**When to add an explicit entry in `top-level.nix`:**
- Only add an explicit entry if the **inputs deviate** from the inputs declared in the nix expression
- Or if you need to override default arguments
- Or if you need to provide additional configuration

**Example of explicit entry (when needed):**
```nix
# In top-level.nix
libxslt = callPackage ./pkgs/libxslt {
  # Override default inputs
  pythonSupport = false;
  cryptoSupport = true;
};
```

#### `pkgs-many/` Directory

Packages that produce multiple variants should use the `mkManyVariants` paradigm and be placed in `pkgs-many/`.

**Example structure:**
```
pkgs-many/
  python/
    default.nix  # Uses mkManyVariants to create python39, python310, python311, etc.
```

The variants are automatically available in the package scope (e.g., `pkgs.python39`, `pkgs.python310`).

## Packaging Conventions

### Meta Attributes

**Remove or clear the `meta.maintainers` field:**

Maintainership will be tracked through tooling

```nix
# CORRECT
meta = {
  description = "Example package";
  license = lib.licenses.mit;
  maintainers = [ ];  # Empty list
};

# INCORRECT
meta = {
  description = "Example package";
  license = lib.licenses.mit;
  maintainers = with lib.maintainers; [ alice bob ];  # Don't include maintainers
};
```

### Testing

**Default behavior:**
- `doCheck = false;` is now the default - do NOT explicitly set this unless you're enabling tests

**Preferred way to run tests:**
```nix
stdenv.mkDerivation (finalAttrs: {
  pname = "example";
  version = "1.0.0";

  # Don't set doCheck = false; it's already the default

  # Instead, use passthru.tests for unit tests
  passthru.tests = {
    unittests = runUnitTests finalAttrs.finalPackage;
  };

  meta = {
    description = "Example package";
  };
})
```

### Build Systems

**Meson packages:**

For packages using Meson as a build system, ensure you include the `meson.configurePhaseHook`:

```nix
nativeBuildInputs = [
  meson
  meson.configurePhaseHook  # Required for Meson configure phase
  ninja
  pkg-config
];

mesonBuildType = "release";  # Specify build type
```

**CMake packages:**

For packages using cmake as a build system, ensure you include the `cmake.configurePhaseHook`:

```nix
nativeBuildInputs = [
  cmake
  cmake.configurePhaseHook  # Required for CMake configure phase
];
```


## Validation Requirements

All added or edited package attributes **must** pass the following validation steps:

### 1. Evaluation Check

Verify the package evaluates correctly:

```bash
nix-instantiate -A <package-name>
```

**Example:**
```bash
nix-instantiate -A libxslt
nix-instantiate -A bubblewrap
nix-instantiate -A rpm
```

This checks that:
- The Nix expression has no syntax errors
- All dependencies are available
- The derivation can be instantiated

### 2. Build Check

Verify the package builds successfully:

```bash
nix-build -A <package-name>
```

**Example:**
```bash
nix-build -A libxslt
nix-build -A bubblewrap
nix-build -A rpm
```

This ensures:
- The package compiles without errors
- All build dependencies are correct
- The build produces expected outputs

### 3. Format Check

All edited Nix files **must** be formatted using `nix fmt`:

```bash
nix fmt <path-to-file>
```

**Examples:**
```bash
nix fmt pkgs/libxslt/default.nix
nix fmt pkgs/bubblewrap/default.nix
nix fmt top-level.nix
```

**Important:** Always run `nix fmt` on files you've modified before considering the work complete.

## Common Patterns

### Porting from nixpkgs

When porting a package from nixpkgs to core-pkgs:

1. **Copy the package files** to the appropriate directory (`pkgs/` or `pkgs-many/`)
2. **Remove/clear `meta.maintainers`** field
3. **Remove update scripts** (e.g., `updateScript = gnome.updateScript { ... }`)
4. **Check dependencies** - ensure all dependencies are available in core-pkgs
5. **Add TODO comments** for missing dependencies:
   ```nix
   # TODO(corepkgs): Port pexpect when needed for msVarsTemplate support
   ```
6. **Validate** using the validation steps above
7. **Format** the file with `nix fmt`

### Example: Complete Package Port

```nix
{
  lib,
  stdenv,
  fetchFromGitHub,
  meson,
  ninja,
  pkg-config,
  libcap,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "example";
  version = "1.0.0";

  src = fetchFromGitHub {
    owner = "example";
    repo = "example";
    rev = "v${finalAttrs.version}";
    hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
  };

  nativeBuildInputs = [
    meson
    meson.configurePhaseHook
    ninja
    pkg-config
  ];

  buildInputs = [
    libcap
  ];

  mesonBuildType = "release";

  # doCheck = false; is the default, don't set it

  passthru.tests = {
    # Add tests here if needed
  };

  meta = {
    description = "Example package";
    homepage = "https://github.com/example/example";
    license = lib.licenses.mit;
    maintainers = [ ];  # Empty list
    platforms = lib.platforms.linux;
  };
})
```

## Validation Checklist

Before submitting changes, ensure:

- [ ] Package directory created in `pkgs/` or `pkgs-many/` as appropriate
- [ ] Explicit `top-level.nix` entry only if inputs deviate from defaults
- [ ] `meta.maintainers = [ ];` (empty list)
- [ ] No `doCheck = false;` unless specifically enabling tests
- [ ] Tests use `passthru.tests.unittests` pattern if applicable
- [ ] `nix-instantiate -A <package>` succeeds
- [ ] `nix-build -A <package>` succeeds
- [ ] `nix fmt <file>` run on all edited files
- [ ] TODO comments added for missing dependencies

## Additional Notes

### Update Scripts

Remove nixpkgs-specific update scripts when porting packages:

```nix
# REMOVE THIS:
passthru = {
  updateScript = gnome.updateScript {
    packageName = pname;
    versionPolicy = "none";
  };
};

# REPLACE WITH:
passthru = {
  # Only include necessary passthru attributes
};
```

### Strict Dependencies

Enable strict dependencies when possible:

```nix
strictDeps = true;
```

This ensures proper separation of build-time and runtime dependencies.

### Cross-Compilation

For packages supporting cross-compilation, use the appropriate dependency sets:

```nix
depsBuildBuild = [ pkg-config ];  # Build platform tools
nativeBuildInputs = [ meson ninja ];  # Build platform tools for host build
buildInputs = [ libcap ];  # Host platform libraries
```
