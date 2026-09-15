---
name: mkekapackage
description: Write mkEkaPackage expressions for corepkgs. Use when creating or reviewing packages that use mkEkaPackage — covers scope-based dependency declaration, the cc attribute, conditional dependencies, overrides, and migration from mkDerivation.
---

# mkEkaPackage

`mkEkaPackage` is the preferred way to define packages in core-pkgs. It
replaces `stdenv.mkDerivation` with scope-based dependency declaration:
dependencies are pulled from the package scope inside `commands` and
`libraries` functions rather than injected via `callPackage` arguments.

## Minimal Example

```nix
{ mkEkaPackage, fetchFromGitHub, lib }:

mkEkaPackage (finalAttrs: {
  pname = "example";
  version = "1.0.0";

  src = fetchFromGitHub {
    owner = "example";
    repo = "example";
    tag = "v${finalAttrs.version}";
    hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
  };

  commands = scope: {
    inherit (scope) pkg-config;
  };

  libraries = scope: {
    inherit (scope) zlib openssl;
  };

  meta = {
    description = "Example package";
    license = lib.licenses.mit;
    platforms = lib.platforms.unix;
  };
})
```

## Key Differences from mkDerivation

| `mkDerivation` | `mkEkaPackage` |
|----------------|----------------|
| `stdenv.mkDerivation` | `mkEkaPackage` (scope member, not on stdenv) |
| `nativeBuildInputs = [ cmake pkg-config ];` | `commands = scope: { inherit (scope) cmake pkg-config; };` |
| `buildInputs = [ zlib openssl ];` | `libraries = scope: { inherit (scope) zlib openssl; };` |
| Dependencies in `callPackage` args | Dependencies from scope; only `mkEkaPackage`, fetchers, `lib`, and config flags in args |
| `clangStdenv.mkDerivation` | `cc = scope: scope.clang;` |
| `stdenvNoCC.mkDerivation` | `cc = null;` |

## Function Arguments

The `callPackage` argument list should contain **only**:

- `mkEkaPackage` — the builder
- Fetchers (`fetchurl`, `fetchFromGitHub`, etc.) — these are functions, not derivations
- `lib` — when needed for helpers
- Configuration flags (`withFoo ? false`, etc.)

**All package dependencies** (libraries, build tools, setup hooks) must come
from the scope passed to `commands` and `libraries`. Do not inherit package
dependencies from the `callPackage` arguments.

```nix
# CORRECT — dependencies come from scope
{ mkEkaPackage, fetchurl, lib, withGui ? false }:

mkEkaPackage (finalAttrs: {
  # ...
  commands = scope: {
    inherit (scope) pkg-config;
  };
  libraries = scope: {
    inherit (scope) zlib;
  } // lib.optionalAttrs withGui {
    inherit (scope) gtk3;
  };
})
```

```nix
# WRONG — do not pull package dependencies from callPackage args
{ mkEkaPackage, fetchurl, lib, zlib, pkg-config, gtk3, withGui ? false }:

mkEkaPackage (finalAttrs: {
  # ...
  commands = scope: {
    inherit pkg-config;  # BAD: from callPackage, not scope
  };
  libraries = scope: {
    inherit zlib;        # BAD: from callPackage, not scope
  };
})
```

## Dependency Declaration

Dependencies are declared as functions that receive the appropriate package
scope and return a named attrset.

| Attribute | Replaces | Scope received |
|-----------|----------|----------------|
| `commands` | `nativeBuildInputs` | `pkgsBuildHost` |
| `libraries` | `buildInputs` | `pkgsHostTarget` |
| `propagatedCommands` | `propagatedNativeBuildInputs` | `pkgsBuildHost` |
| `propagatedLibraries` | `propagatedBuildInputs` | `pkgsHostTarget` |
| `depsBuildBuild` | `depsBuildBuild` | `pkgsBuildBuild` |
| `depsBuildTarget` | `depsBuildTarget` | `pkgsBuildTarget` |
| `depsHostHost` | `depsHostHost` | `pkgsHostHost` |
| `depsTargetTarget` | `depsTargetTarget` | `pkgsTargetTarget` |

Each attrset is flattened to a list (via `builtins.attrValues`), with `null`
values filtered out and `getDev` applied. The flattened lists are passed to
the underlying derivation call.

## CC Attribute

The `cc` attribute controls which C compiler is used. It is separate from
`commands` and resolved before dependency flattening.

```nix
# Default — omit cc; uses mkEkaPackage.cc (same as stdenv.cc)
mkEkaPackage (finalAttrs: {
  pname = "normal-package";
  # ...
})

# Use Clang (replaces clangStdenv)
mkEkaPackage (finalAttrs: {
  pname = "mesa";
  # ...
  cc = scope: scope.clang;
})

# Pin a GCC version (replaces gcc12Stdenv)
mkEkaPackage (finalAttrs: {
  pname = "legacy-app";
  # ...
  cc = scope: scope.gcc12;
})

# No compiler (replaces stdenvNoCC)
mkEkaPackage (finalAttrs: {
  pname = "tzdata";
  # ...
  cc = null;
})
```

When `cc` is a function, it receives `pkgsBuildHost`. The resolved `cc` is
merged into `commands` under the key `cc` (user `commands` entries with key
`cc` take precedence). Hardening flags are derived from the resolved compiler.

## Conditional Dependencies

Two patterns:

```nix
# Null filtering — good for single deps
libraries = scope: {
  inherit (scope) openssl zlib;
  perl = if withPerl then scope.perl else null;
};

# optionalAttrs — good for groups
libraries = scope: {
  inherit (scope) openssl zlib;
} // lib.optionalAttrs withGui {
  inherit (scope) gtk3 cairo pango;
};
```

## Referencing Dependencies in Phases

Access resolved dependencies through `finalAttrs`:

```nix
mkEkaPackage (finalAttrs: {
  # ...
  commands = scope: {
    cmake = scope.cmake.minimal;
  };

  checkPhase = ''
    ${lib.getBin finalAttrs.commands.cmake}/bin/ctest --test-dir build
  '';
})
```

## Non-Scope Items

Items not in the package scope can be added directly:

```nix
commands = scope: {
  inherit (scope) pkg-config ninja;
  mesonHook = scope.meson.configurePhaseHook;   # sub-attributes
  myLocalTool = someLocalDerivation;             # locally defined
};
```

## Overriding

`overrideAttrs` composes naturally with scope-based dependencies:

```nix
# Add a dependency
pkg.overrideAttrs (prev: {
  libraries = scope: prev.libraries scope // { extra = scope.extra; };
})

# Remove a dependency
pkg.overrideAttrs (prev: {
  libraries = scope: removeAttrs (prev.libraries scope) [ "libxslt" ];
})

# Replace a dependency
pkg.overrideAttrs (prev: {
  libraries = scope: prev.libraries scope // { openssl = myCustomOpenssl; };
})

# Switch the compiler
pkg.overrideAttrs {
  cc = scope: scope.clang;
}
```

## CMake Packages

```nix
{ mkEkaPackage, fetchFromGitHub, lib }:

mkEkaPackage (finalAttrs: {
  pname = "example";
  version = "1.0.0";

  src = fetchFromGitHub {
    owner = "example";
    repo = "example";
    tag = "v${finalAttrs.version}";
    hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
  };

  commands = scope: {
    inherit (scope) pkg-config;
    cmake = scope.cmake;
    cmakeHook = scope.cmake.configurePhaseHook;
  };

  libraries = scope: {
    inherit (scope) zlib openssl;
  };

  cmakeFlags = [
    "-DBUILD_SHARED_LIBS=ON"
  ];

  meta = {
    description = "Example CMake package";
    license = lib.licenses.mit;
  };
})
```

## Meson Packages

```nix
{ mkEkaPackage, fetchurl, lib }:

mkEkaPackage (finalAttrs: {
  pname = "example";
  version = "2.0.0";

  src = fetchurl {
    url = "https://example.com/example-${finalAttrs.version}.tar.xz";
    hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
  };

  commands = scope: {
    inherit (scope) pkg-config ninja;
    mesonHook = scope.meson.configurePhaseHook;
  };

  libraries = scope: {
    inherit (scope) glib gtk3;
  };

  meta = {
    description = "Example Meson package";
    license = lib.licenses.gpl3Plus;
  };
})
```

## Introspection

`mkEkaPackage` is an attrset with `__functor`, so it can be inspected:

- `mkEkaPackage.cc` — the default C compiler
- `mkEkaPackage.stdenv.hostPlatform` — platform information
- `mkEkaPackage.scopes.buildHost` — the build-time package scope

## Complete Example

```nix
{
  mkEkaPackage,
  fetchurl,
  lib,
  withPerl ? false,
}:

mkEkaPackage (finalAttrs: {
  pname = "nginx";
  version = "1.30.4";

  src = fetchurl {
    url = "https://nginx.org/download/nginx-${finalAttrs.version}.tar.gz";
    hash = "sha256-QmHckOnkfBxAQSdumqo9SOvi5mT3KOFPqVrmxn1XoIs=";
  };

  commands = scope: {
    inherit (scope) installShellFiles removeReferencesTo;
  };

  libraries = scope: {
    inherit (scope) openssl zlib pcre2 libxml2 libxslt;
  } // lib.optionalAttrs withPerl {
    inherit (scope) perl;
  };

  meta = {
    description = "HTTP and reverse proxy server";
    license = lib.licenses.bsd2;
    platforms = lib.platforms.unix;
  };
})
```
