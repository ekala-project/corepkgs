---
name: packaging
description: corepkgs packaging conventions. Use when writing or reviewing any pkgs/<name>/default.nix — covers the finalAttrs pattern, meta attributes, where each kind of dependency belongs, fetchers, patching, install phases, multiple outputs, and passthru.
---

# Packaging Conventions

## Package Structure

Use `finalAttrs` pattern for self-referencing:

```nix
stdenv.mkDerivation (finalAttrs: {
  pname = "example";
  version = "1.0.0";

  src = fetchFromGitHub {
    owner = "example";
    repo = "example";
    tag = "v${finalAttrs.version}";
    hash = "sha256-...";
  };

  passthru.tests = {
    unittests = runUnitTests finalAttrs.finalPackage;
  };
})
```

## Meta Attributes

**Required fields:**
```nix
meta = {
  description = "Brief description";
  license = lib.licenses.mit;
  platforms = lib.platforms.linux;
};
```

**Common licenses:**
```nix
license = lib.licenses.mit;
license = lib.licenses.gpl3Plus;
license = with lib.licenses; [ gpl2Plus lgpl21Plus ];
```

**Platform options:**
```nix
platforms = lib.platforms.linux;    # Linux only
platforms = lib.platforms.unix;     # Unix-like
platforms = lib.platforms.darwin;   # macOS only
platforms = lib.platforms.all;      # All platforms
```

## Testing

**Goal:** Keep builds as fast as possible by disabling in-build tests. Use `passthru.tests` to preserve test coverage without slowing every build.

### Defaults

`doCheck = false;` and `doInstallCheck = false;` are the defaults across all build systems (`stdenv.mkDerivation`, `buildPythonPackage`, `buildRustPackage`, `buildGoModule`, `buildPerlPackage`). Don't set them explicitly.

### Auto-Generated `passthru.tests.build`

`buildRustPackage` and `buildGoModule` automatically provide `passthru.tests.build` — a variant that re-runs the build with `doCheck = true`. User-supplied `passthru.tests` entries are merged alongside, not replaced.

For `stdenv.mkDerivation` packages, add `passthru.tests` manually:

```nix
passthru.tests = {
  withChecks = finalAttrs.finalPackage.overrideAttrs { doCheck = true; };
};
```

### Python: `testPaths` (Preferred)

Set `testPaths` to auto-generate `passthru.tests.python` and a `test_src` output:

```nix
nativeCheckInputs = [ pytestCheckHook ];
testPaths = [ "tests" ];
```

The `test_src` output bundles the listed paths plus config files (`conftest.py`, `pyproject.toml`, etc.). A standalone test derivation runs the suite against the installed package.

For suites that need extra files (helper modules, fixture data):
```nix
testPaths = [ "tests" "src/helpers" "README.rst" ];
```

Test configuration attributes are forwarded automatically:
- `disabledTests`, `disabledTestPaths`, `enabledTestPaths`
- `pytestFlags`, `pytestFlagsArray`, `unittestFlagsArray`
- `preCheck`, `postCheck`, `preInstallCheck`, `postInstallCheck`

### Python: Manual `tests.nix` (Fallback)

When `testPaths` is not suitable (e.g., circular dependencies with pytest), create a separate `tests.nix`:

```nix
# default.nix
passthru.tests = {
  pytest = callPackage ./tests.nix { };
};
```

### Acceptable In-Build Checks

`doInstallCheck = true;` is acceptable for:
- `versionCheckHook` — verifies the built binary runs and prints expected version
- `pythonImportsCheck` — runs automatically in `buildPythonPackage`, no need to enable explicitly

## Dependencies

```nix
nativeBuildInputs = [    # Build tools (build platform)
  pkg-config
  cmake
];

buildInputs = [          # Libraries (host platform)
  zlib
  openssl
];

checkInputs = [          # Test dependencies
  pytest
];

propagatedBuildInputs = [ # Runtime deps for dependents
  python3
];
```

**Cross-compilation:**
```nix
strictDeps = true;

depsBuildBuild = [ pkg-config ];    # Build -> build tools
nativeBuildInputs = [ cmake ];      # Build -> host tools
buildInputs = [ zlib ];             # Host libraries
```

## Fetching Sources

**GitHub:**
```nix
src = fetchFromGitHub {
  owner = "example";
  repo = "example";
  tag = "v${finalAttrs.version}";
  hash = "sha256-...";
};
```

**GitLab:**
```nix
src = fetchFromGitLab {
  domain = "gitlab.com";
  owner = "example";
  repo = "example";
  tag = finalAttrs.version;
  hash = "sha256-...";
};
```

**Tarball:**
```nix
src = fetchurl {
  url = "https://example.com/releases/example-${finalAttrs.version}.tar.gz";
  hash = "sha256-...";
};
```

## Patching

**Substitutions:**
```nix
postPatch = ''
  substituteInPlace Makefile \
    --replace '/usr/local' "$out" \
    --replace 'python' '${python3}/bin/python3'
'';
```

**Patch files:**
```nix
patches = [
  ./fix-build.patch
  (fetchpatch {
    url = "https://github.com/example/example/commit/abc123.patch";
    hash = "sha256-...";
  })
];
```

## Install Phase

```nix
installPhase = ''
  runHook preInstall

  mkdir -p $out/bin
  cp example $out/bin/

  runHook postInstall
'';
```

**Post-install fixups:**
```nix
postInstall = ''
  wrapProgram $out/bin/example \
    --prefix PATH : ${lib.makeBinPath [ coreutils ]}
'';
```

## Multiple Outputs

```nix
outputs = [ "out" "dev" "doc" ];

postInstall = ''
  moveToOutput include $dev
  moveToOutput share/doc $doc
'';
```

## Passthru

```nix
passthru = {
  tests = {
    unittests = runUnitTests finalAttrs.finalPackage;
  };

  plugins = {
    foo = callPackage ./plugins/foo.nix { };
  };
};
```

## Porting from nixpkgs

**Remove:**
- `updateScript` from passthru
- Maintainers list (set to `[ ]`)
- nixpkgs-specific test infrastructure

**Add TODO for missing deps:**
```nix
buildInputs = [
  zlib
  # TODO(corepkgs): Port openssl for TLS support
];
```

## Complete Example

```nix
{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
  pkg-config,
  zlib,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "example";
  version = "2.1.0";

  src = fetchFromGitHub {
    owner = "example-org";
    repo = "example";
    tag = "v${finalAttrs.version}";
    hash = "sha256-...";
  };

  nativeBuildInputs = [
    cmake
    cmake.configurePhaseHook
    pkg-config
  ];

  buildInputs = [ zlib ];

  strictDeps = true;
  cmakeBuildType = "Release";

  passthru.tests = {
    unittests = runUnitTests finalAttrs.finalPackage;
  };

  meta = {
    description = "Example library";
    homepage = "https://github.com/example-org/example";
    license = lib.licenses.mit;
    platforms = lib.platforms.unix;
  };
})
```
