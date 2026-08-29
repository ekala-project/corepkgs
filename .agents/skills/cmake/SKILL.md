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

### CMake Flags

```nix
cmakeFlags = [
  "-DBUILD_SHARED_LIBS=ON"
  "-DENABLE_TESTS=OFF"
  "-DCMAKE_INSTALL_LIBDIR=lib"
];
```

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
cmakeFlags = [
  "-DZLIB_ROOT=${zlib}"
  "-DOPENSSL_ROOT_DIR=${openssl}"
];
```

**Library install to lib64:**
```nix
cmakeFlags = [ "-DCMAKE_INSTALL_LIBDIR=lib" ];
```

**Install prefix issues:**
```nix
cmakeFlags = [ "-DCMAKE_INSTALL_PREFIX=${placeholder "out"}" ];
```
