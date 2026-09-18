---
name: cmake
description: Package a CMake-based project for corepkgs. Use when a source tree has a CMakeLists.txt — covers the minimal derivation, cmakeFlags, cross-compilation, and diagnosing CMake configure failures.
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

### CMake Flags (Legacy)

`cmakeFlags` still works for string-based flags and non-`-D` flags:

```nix
cmakeFlags = [
  "-DBUILD_SHARED_LIBS=ON"
  "-DENABLE_TESTS=OFF"
  "-DCMAKE_INSTALL_LIBDIR=lib"
];
```

Both can be used together. `cmakeFlags` values override `cmakeEntries` for the
same key (cmake uses last-wins for `-D` flags). Use `cmakeFlags` for non-`-D`
flags like `-Wno-dev` or `-GNinja`.

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
