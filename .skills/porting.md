# Porting from nixpkgs

## Workflow

### 1. Check Dependencies

**Before copying files**, verify all dependencies exist:

```bash
# Check multiple dependencies
for dep in acl lzo cmocka libuuid util-linux zlib zstd; do
  echo -n "$dep: "
  nix-instantiate -A $dep >/dev/null 2>&1 && echo "✓" || echo "✗"
done
```

**If missing:**
- Port the dependency first, OR
- Add TODO comment and disable feature

### 2. Copy Package Files

```bash
# Single package -> pkgs/
cp -r /path/to/nixpkgs/pkgs/development/libraries/libxslt pkgs/libxslt/

# Package with variants -> pkgs-many/
cp -r /path/to/nixpkgs/pkgs/development/languages/python pkgs-many/python/
```

### 3. Clean Up

**Remove:**
```nix
# Remove maintainers
meta.maintainers = [ ];  # Set to empty

# Remove update scripts
passthru = {
  # updateScript = gnome.updateScript { ... };  # DELETE
  tests = { ... };  # Keep tests
};
```

**Adjust testing:**
```nix
# doCheck = false is default - don't set it
# Or use passthru.tests instead
passthru.tests = {
  unittests = runUnitTests finalAttrs.finalPackage;
};
```

### 4. Add TODO Comments

```nix
buildInputs = [
  zlib
  # TODO(corepkgs): Port openssl for TLS support
  # TODO(corepkgs): Port libxml2 for XML processing
];
```

### 5. Validate

```bash
nix-instantiate -A example
nix-build -A example
./result/bin/example --version
nix fmt pkgs/example/default.nix
```

### 6. Add to top-level.nix (If Needed)

**Only if:**
- Inputs deviate from defaults
- Need to override arguments
- Need additional configuration

Otherwise packages in `pkgs/` and `pkgs-many/` are auto-registered.

## Example: Simple Package

```nix
{
  lib,
  stdenv,
  fetchFromGitHub,
  meson,
  ninja,
  pkg-config,
  libcap,
  libseccomp,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "bubblewrap";
  version = "0.8.0";

  src = fetchFromGitHub {
    owner = "containers";
    repo = "bubblewrap";
    rev = "v${finalAttrs.version}";
    hash = "sha256-...";
  };

  nativeBuildInputs = [
    meson
    meson.configurePhaseHook
    ninja
    pkg-config
  ];

  buildInputs = [
    libcap
    libseccomp
  ];

  mesonBuildType = "release";

  meta = {
    description = "Unprivileged sandboxing tool";
    homepage = "https://github.com/containers/bubblewrap";
    license = lib.licenses.lgpl2Plus;
    maintainers = [ ];  # Cleaned
    platforms = lib.platforms.linux;
  };
})
```

## Example: Missing Dependencies

```nix
{
  lib,
  stdenv,
  fetchurl,
  pkg-config,
  zlib,
  bzip2,
  file,
  lua,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "rpm";
  version = "4.18.0";

  src = fetchurl {
    url = "https://ftp.rpm.org/releases/rpm-4.18.x/rpm-${finalAttrs.version}.tar.bz2";
    hash = "sha256-...";
  };

  nativeBuildInputs = [ pkg-config ];

  buildInputs = [
    zlib
    bzip2
    file
    lua
    # TODO(corepkgs): Port popt for enhanced CLI parsing
    # TODO(corepkgs): Port beecrypt for signature verification
  ];

  configureFlags = [
    "--without-selinux"
    "--without-cap"
  ];

  meta = {
    description = "RPM Package Manager";
    license = lib.licenses.gpl2Plus;
    maintainers = [ ];
  };
})
```

## Package Variants (pkgs-many)

For packages with multiple versions:

```nix
# pkgs-many/python/default.nix
mkManyVariants {
  variants = {
    python39 = { version = "3.9.18"; };
    python310 = { version = "3.10.13"; };
    python311 = { version = "3.11.7"; };
  };
  # ...
}
```

Creates `pkgs.python39`, `pkgs.python310`, etc.

## Common Issues

**Evaluation fails - missing dependency:**
```
error: attribute 'somelib' missing
```
→ Port dependency or add TODO and disable.

**Build fails - feature requires missing dep:**
```
configure: error: libfoo is required
```
→ Disable with `configureFlags = [ "--without-foo" ];`

**Tests fail:**
→ Tests are disabled by default in core-pkgs.

**Update script errors:**
→ Remove `updateScript` from `passthru`.

## Checklist

- [ ] Dependencies checked with `nix-instantiate`
- [ ] Missing deps documented with TODO
- [ ] `meta.maintainers = [ ]`
- [ ] Update scripts removed
- [ ] Tests configured appropriately
- [ ] `nix-instantiate -A <package>` succeeds
- [ ] `nix-build -A <package>` succeeds
- [ ] `nix fmt` run on all files
- [ ] License preserved accurately
- [ ] Security patches preserved
