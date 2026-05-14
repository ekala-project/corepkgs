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
    rev = "v${finalAttrs.version}";
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
  maintainers = [ ];  # Always empty
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

**Default:** `doCheck = false;` - Don't set explicitly.

**Preferred pattern:**
```nix
passthru.tests = {
  unittests = runUnitTests finalAttrs.finalPackage;
};
```

**Enable tests only when essential:**
```nix
doCheck = true;
checkInputs = [ pytest ];
```

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
  rev = "v${finalAttrs.version}";
  hash = "sha256-...";
};
```

**GitLab:**
```nix
src = fetchFromGitLab {
  domain = "gitlab.com";
  owner = "example";
  repo = "example";
  rev = finalAttrs.version;
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
    rev = "v${finalAttrs.version}";
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
    maintainers = [ ];
    platforms = lib.platforms.unix;
  };
})
```
