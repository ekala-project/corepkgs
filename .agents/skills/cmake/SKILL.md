---
name: cmake
description: Package a CMake-based project for corepkgs. Use when a source tree has a CMakeLists.txt — covers the minimal derivation, cmakeEntries, cross-compilation, and diagnosing CMake configure failures.
---

# CMake Build System

## Minimal Example

```nix
{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "example";
  version = "1.0.0";

  src = fetchFromGitHub {
    owner = "example";
    repo = "example";
    tag = "v${finalAttrs.version}";
    hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
  };

  nativeBuildInputs = [
    cmake
    cmake.configurePhaseHook  # Required
  ];

  meta = {
    description = "Example CMake package";
    license = lib.licenses.mit;
  };
})
```

## Essential Requirements

**Always include** `cmake.configurePhaseHook` in `nativeBuildInputs`.

- `cmake` alone provides the cmake binary and the setup hook (`setup-hook.sh`),
  which defines all `cmakeEntries` helpers (`setCMakeEntry`, `prependCMakeEntry`,
  `concatCMakeEntryFlagsTo`, etc.) and `cmakeConfigurePhase`.
- `cmake.configurePhaseHook` replaces the default configure phase with
  `cmakeConfigurePhase`, which assembles `cmakeEntries` + `cmakeFlags` into the
  final cmake invocation. Without it, the configure phase is the generic
  autotools-style one and cmake entries/flags are ignored.

## Common Patterns

### With Dependencies

```nix
nativeBuildInputs = [
  cmake
  cmake.configurePhaseHook
  pkg-config
];

buildInputs = [
  zlib
  openssl
];
```

### CMake Entries (Preferred)

Use `cmakeEntries` to specify CMake `-D` cache entries as a structured attrset.
Booleans are automatically converted to `ON`/`OFF`.

```nix
cmakeEntries = {
  BUILD_SHARED_LIBS = true;
  ENABLE_TESTS = false;
  CMAKE_INSTALL_LIBDIR = "lib";
};
```

### CMake Flags (non-`-D` only)

`cmakeFlags` is reserved for non-`-D` flags (warning suppression, generator
selection, source-dir overrides, unset flags). **All `-D` entries must use
`cmakeEntries`.**

```nix
cmakeFlags = [
  "-Wno-dev"
  "-H.."
  "-UCMAKE_INSTALL_LIBDIR"  # unset (-U), not a -D flag
];
```

Both can be used together. `cmakeEntries` entries are emitted first, then
`cmakeFlags` / `cmakeFlagsArray` are appended.

### Cross-Compilation

```nix
strictDeps = true;

nativeBuildInputs = [ cmake cmake.configurePhaseHook pkg-config ];
buildInputs = [ zlib ];
depsBuildBuild = [ pkg-config ];
```

## Troubleshooting

**CMake can't find dependencies:**
```nix
cmakeEntries = {
  ZLIB_ROOT = "${zlib}";
  OPENSSL_ROOT_DIR = "${openssl}";
};
```

**Library install to lib64:**
```nix
cmakeEntries = {
  CMAKE_INSTALL_LIBDIR = "lib";
};
```

**Install prefix issues:**
```nix
cmakeEntries = {
  CMAKE_INSTALL_PREFIX = "${placeholder "out"}";
};
```
