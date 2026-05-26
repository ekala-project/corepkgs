# mkManyVariants - Multi-Version Package Management

This skill helps you work with the `mkManyVariants` pattern used in this codebase for managing packages that need to support multiple versions (e.g., guile, go, erlang, perl, openssl).

## Key Differences from Normal Nix Packages

Unlike a standard Nix package (like `pkgs/xxHash/default.nix`) which is a single `default.nix` file, mkManyVariants packages are split into **three separate files**:

### Normal Package Structure (e.g., `pkgs/xxHash/`)
```
pkgs/xxHash/
└── default.nix          # Single file with version, src, buildInputs, etc.
```

### mkManyVariants Package Structure (e.g., `pkgs-many/isl/`)
```
pkgs-many/isl/
├── default.nix          # Calls mkManyVariants with configuration
├── generic.nix          # Generic builder that works for all versions
├── variants.nix         # Defines each version's specific data
└── patches/             # Optional: version-specific patches
    ├── 0.20/
    └── 0.23/
```

## The Three-File Pattern

### 1. `default.nix` - Configuration Entry Point

This file calls `mkManyVariants` with configuration:

```nix
{ mkManyVariants, callPackage }:

mkManyVariants {
  variants = ./variants.nix;           # Where version data lives
  aliases = { };                       # Deprecated/aliased versions
  defaultSelector = (p: p.v0_20);     # Which version is the default
  genericBuilder = ./generic.nix;      # Builder that handles all versions
  inherit callPackage;
}
```

**Differences from normal package:**
- No `stdenv.mkDerivation` call
- No version/src/buildInputs specified here
- Instead, configures mkManyVariants framework

### 2. `variants.nix` - Version Definitions

This file contains an attribute set where each attribute represents a version:

```nix
{
  v0_20 = rec {
    version = "0.20";
    src-url = [
      "https://libisl.sourceforge.io/isl-${version}.tar.xz"
    ];
    src-hash = "sha256-pVlqn7ils2XLYS5LlihzXW5n6RePrhNKgWrhlQF+d6o=";
    configureFlags = [
      "--with-gcc-arch=generic"
    ];
  };

  v0_23 = rec {
    version = "0.23";
    src-url = [
      "https://libisl.sourceforge.io/isl-${version}.tar.xz"
    ];
    src-hash = "sha256-XvxT767xUTAfTn3eOFa2aBLYFT3t4k+rF2c/gByGmPI=";
    configureFlags = [
      "--with-gcc-arch=generic"
    ];
  };
}
```

**Key points:**
- Each version is a separate attribute (typically named `v<major>_<minor>`)
- Use `rec` to allow self-referencing (e.g., `version` in `src-url`)
- Common fields: `version`, `src-url`, `src-hash`
- Version-specific fields: `configureFlags`, `patches`, `cmakeFlags`, etc.

### 3. `generic.nix` - Generic Builder with Conditional Logic

This file is a **two-stage function** that receives variant args first, then package args:

```nix
{
  version,
  src-url,
  src-hash,
  configureFlags ? [ ],
  patches ? [ ],
  packageAtLeast,     # Helper: version >= X
  packageOlder,       # Helper: version < X
  ...
}@variantArgs:

{
  lib,
  stdenv,
  fetchurl,
  gmp,
  buildPackages,
  ...
}@args:

stdenv.mkDerivation {
  pname = "isl";
  inherit version;

  src = fetchurl {
    url = src-url;
    hash = src-hash;
  };

  inherit patches;

  # Version-conditional logic using helper functions
  strictDeps = true;
  depsBuildBuild = lib.optionals (packageAtLeast "0.23") [
    buildPackages.stdenv.cc
  ];

  nativeBuildInputs =
    lib.optionals (stdenv.hostPlatform.isRiscV && packageOlder "0.23") [
      autoreconfHook
    ] ++ [
      updateAutotoolsGnuConfigScriptsHook
    ];

  inherit configureFlags;

  meta = { ... };
}
```

**Key differences from normal package:**
- **Two parameter sets**: First `variantArgs`, then package dependencies
- **Helper functions available**: `packageAtLeast`, `packageOlder`, `packageBetween`
- **Conditional logic**: Use helpers to vary dependencies/patches by version
- **Generic src handling**: Takes `src-url` and `src-hash` from variants

## Version Helper Functions

These functions are automatically injected into `variantArgs`:

### `packageOlder`
```nix
packageOlder "2.0"  # Returns true if version < 2.0
```

### `packageAtLeast`
```nix
packageAtLeast "2.0"  # Returns true if version >= 2.0
```

### `packageBetween`
```nix
packageBetween "2.0" "3.0"  # Returns true if 2.0 <= version < 3.0
```

### Real-world examples from guile:

```nix
# Different source extensions by version
srcExtension = if packageOlder "2.0" then "tar.gz" else "tar.xz";

# Version ranges
patches =
  lib.optionals (packageOlder "2.0") [
    ./patches/1.8/...
  ]
  ++ lib.optionals (packageAtLeast "2.0" && packageOlder "2.2") [
    ./patches/2.0/...
  ]
  ++ lib.optionals (packageAtLeast "2.2") [
    ./patches/2.2/...
  ];

# Platform-specific conditionals with version
configureFlags = lib.optional (packageAtLeast "3.0" && stdenv.hostPlatform.isDarwin)
  "--disable-lto";
```

## Common Patterns

### Pattern 1: Version-Specific Patches
```nix
patches = [ ]
  ++ lib.optionals (packageOlder "2.0") [
    ./patches/1.x/fix-something.patch
  ]
  ++ lib.optionals (packageAtLeast "2.0") [
    ./patches/2.x/new-fix.patch
  ];
```

### Pattern 2: Conditional Dependencies
```nix
buildInputs = [
  alwaysNeeded
] ++ lib.optionals (packageAtLeast "3.0") [
  onlyNeededInV3
];
```

### Pattern 3: Setup Hooks by Version
```nix
setupHook =
  if packageOlder "2.0" then
    ./setup-hooks/v1-hook.sh
  else if packageOlder "3.0" then
    ./setup-hooks/v2-hook.sh
  else
    ./setup-hooks/v3-hook.sh;
```

### Pattern 4: Using mkVariantPassthru (Advanced)
```nix
# In generic.nix, add to passthru to enable variant composition
passthru = mkVariantPassthru variantArgs // {
  # other passthru attrs
};
```

This allows accessing other variants from a built package: `isl.variants.v0_27`

## When to Use mkManyVariants

Use mkManyVariants when:
- Package needs **multiple versions** available simultaneously
- Different versions have **conditional dependencies** or build logic
- Versions share **most of the build logic** but differ in specifics
- Want to provide **variant composition** (access to other versions)

Don't use for:
- Single-version packages (use normal `pkgs/` structure)
- Completely different build processes per version (use separate packages)

## Creating a New mkManyVariants Package

1. Create directory in `pkgs-many/<package>/`
2. Create `variants.nix` with your versions
3. Create `generic.nix` with shared build logic and conditionals
4. Create `default.nix` calling mkManyVariants
5. Choose default version with `defaultSelector`
6. Test building: `nix-build -A <package>` (default) and `nix-build -A <package>.variants.v<version>`

## Common Gotchas

- **Don't forget `rec`** in variants.nix if using `${version}` in fields
- **Two-stage function** in generic.nix: variantArgs first, then package args
- **Helper functions** only available in first parameter set (variantArgs)
- **Default selector** must be a function taking the variants attrset
