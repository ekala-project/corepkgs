# Agent Guide for core-pkgs

This document provides high-level guidelines for AI agents working with the core-pkgs repository. For detailed information on specific topics, see the `.skills/` directory.

**Quick access to detailed guides:**
- [`.skills/cmake.md`](.skills/cmake.md) - CMake build system
- [`.skills/meson.md`](.skills/meson.md) - Meson build system
- [`.skills/packaging.md`](.skills/packaging.md) - Packaging conventions
- [`.skills/validation.md`](.skills/validation.md) - Validation and testing
- [`.skills/porting.md`](.skills/porting.md) - Porting from nixpkgs

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
# Uses mkManyVariants to create python39, python310, python311, etc.
pkgs-many/python/default.nix  
```

The variants are automatically available in the package scope (e.g., `pkgs.python39`, `pkgs.python310`).

## Packaging Conventions

### Meta Attributes

**Always set `meta.maintainers` to an empty list:**

```nix
meta = {
  description = "Example package";
  license = lib.licenses.mit;
  maintainers = [ ];  # Always empty
  platforms = lib.platforms.linux;
};
```

**Detailed guide:** See [`.skills/packaging.md`](.skills/packaging.md) for complete meta attribute documentation.

### Testing

**Key points:**
- `doCheck = false;` is the default - don't set it explicitly
- Prefer `passthru.tests` for unit tests
- Only enable `doCheck = true;` for critical packages

**Detailed guide:** See [`.skills/packaging.md`](.skills/packaging.md#testing) for testing patterns.

### Build Systems

**CMake packages:**

Include `cmake.configurePhaseHook` in nativeBuildInputs.

**Detailed guide:** See [`.skills/cmake.md`](.skills/cmake.md) for complete CMake documentation.

**Meson packages:**

Include `meson.configurePhaseHook` and `ninja` in nativeBuildInputs, specify `mesonBuildType`.

**Detailed guide:** See [`.skills/meson.md`](.skills/meson.md) for complete Meson documentation.


## Validation Requirements

All added or edited package attributes **must** pass three validation steps:

### 1. Evaluation Check

```bash
nix-instantiate -A <package-name>
```

Verifies the Nix expression evaluates correctly.

### 2. Build Check

```bash
nix-build -A <package-name>
```

Verifies the package builds successfully.

### 3. Format Check

```bash
nix fmt <path-to-file>
```

Ensures code follows formatting standards.

**Detailed guide:** See [`.skills/validation.md`](.skills/validation.md) for complete validation procedures, troubleshooting, and advanced validation techniques.

## Common Patterns

### Checking if Dependencies Exist

Before porting a package, verify that all required dependencies are available in core-pkgs.

**Use `nix-instantiate` to check if a dependency exists:**

```bash
nix-instantiate -A <dependency-name>
```

If the dependency exists, you'll see the derivation path. If it doesn't exist, you'll get an error.

**Example - checking multiple dependencies:**
```bash
for dep in acl lzo cmocka libuuid util-linux zlib zstd; do
  echo -n "$dep: "
  nix-instantiate -A $dep >/dev/null 2>&1 && echo "✓ available" || echo "✗ missing"
done
```

**Output:**
```
acl: ✓ available
lzo: ✓ available
cmocka: ✓ available
libuuid: ✓ available
util-linux: ✓ available
zlib: ✓ available
zstd: ✓ available
```

**Important:** Do NOT search `top-level.nix` with grep to check for dependencies. Packages in `pkgs/` and `pkgs-many/` are automatically registered and may not appear in `top-level.nix`. Always use `nix-instantiate` to verify availability.

**NOTE:** For non derivation attrs, use `nix-instantiate --eval -A <dep>` which can evaluate to non derivations

### Porting from nixpkgs

When porting a package from nixpkgs:

1. **Check dependencies first** - use `nix-instantiate -A <dep>` to verify all dependencies exist
2. **Copy the package files** to the appropriate directory (`pkgs/` or `pkgs-many/`)
3. **Remove/clear `meta.maintainers`** field
4. **Remove update scripts** (e.g., `updateScript = gnome.updateScript { ... }`)
5. **Add TODO comments** for missing dependencies
6. **Validate** and **format** the files

**Detailed guide:** See [`.skills/porting.md`](.skills/porting.md) for complete porting workflow, examples, and troubleshooting.

## Validation Checklist

Before submitting changes, ensure:

- [ ] All dependencies verified with `nix-instantiate -A <dep>`
- [ ] Package in correct directory (`pkgs/` or `pkgs-many/`)
- [ ] `meta.maintainers = [ ];` (empty list)
- [ ] `nix-instantiate -A <package>` succeeds
- [ ] `nix-build -A <package>` succeeds
- [ ] `nix fmt <file>` run on all edited files
- [ ] TODO comments added for missing dependencies

**Complete checklist:** See [`.skills/validation.md`](.skills/validation.md#validation-checklist) for the full validation checklist.

## ekaos Reusable Modules

ekaos provides **reusable service modules** using a cross-platform service interface that works across systemd, launchd, runit, and BSD rc.d.

**Quick reference:** See `services/AGENTS.md` for service definition syntax and conventions.

**Key points:**
- Service modules in `ekaos/modules/services/` define options at `services.*`
- Services are automatically translated to systemd units
- Same interface works across multiple platforms and contexts
- Full documentation in `services/README.md`

**Example service module structure:**
```nix
services.myservice = {
  enable = true;
  command = "${pkgs.myapp}/bin/myapp";
  args = [ "--port" "8080" ];
  restartPolicy = "always";

  systemd = {
    wantedBy = [ "multi-user.target" ];
  };
};
```

## Additional Resources

For detailed information on specific topics:

- **Build systems:** [`.skills/cmake.md`](.skills/cmake.md) and [`.skills/meson.md`](.skills/meson.md)
- **Packaging:** [`.skills/packaging.md`](.skills/packaging.md) - includes dependency management, cross-compilation, and passthru attributes
- **Validation:** [`.skills/validation.md`](.skills/validation.md) - includes troubleshooting and advanced validation
- **Porting:** [`.skills/porting.md`](.skills/porting.md) - includes complete examples and best practices
- **All skills:** [`.skills/README.md`](.skills/README.md) - index of all available skill guides
