---
name: porting
description: Port a package from nixpkgs into corepkgs. Use when adding a package that already exists upstream — covers importing it with scripts/import-from-nixpkgs.py, checking dependencies first, stripping nixpkgs-only attributes, recording TODOs for missing features, and wiring it into top-level.nix.
---

# Porting from nixpkgs

## Workflow

### 1. Check dependencies exist

Do this **before** importing anything: a package whose dependencies are missing
cannot be evaluated, and it is cheaper to find out now than after editing.

```bash
for dep in acl lzo cmocka libuuid util-linux zlib zstd; do
  printf '%s: ' "$dep"
  nix-instantiate -A "$dep" >/dev/null 2>&1 && echo "✓" || echo "✗"
done
```

Do **not** grep `top-level.nix` to check for a dependency. Packages in `pkgs/`
and `pkgs-many/` are registered automatically and often have no entry there. For
attributes that are not derivations, use `nix-instantiate --eval -A <attr>`.

If a dependency is missing, either port it first or add a TODO and disable the
feature that needs it (step 4).

### 2. Import the package

`scripts/import-from-nixpkgs.py` copies the package directory across and applies
the corepkgs naming convention.

```bash
# pkgs/by-name/cu/curl -> pkgs/curl
./scripts/import-from-nixpkgs.py --name curl

# several at once
./scripts/import-from-nixpkgs.py --name libfoo libbar libbaz

# pkgs/development/python-modules/httpx -> python/pkgs/httpx
./scripts/import-from-nixpkgs.py --name httpx --python

# nixpkgs checkout is somewhere other than ../nixpkgs
./scripts/import-from-nixpkgs.py --name curl --nixpkgs-root ~/src/nixpkgs

# replace a package that was already imported
./scripts/import-from-nixpkgs.py --name curl --force
```

| Source in nixpkgs | Destination | Flag |
| --- | --- | --- |
| `pkgs/by-name/<xx>/<name>` | `pkgs/<name>` | *(default)* |
| `pkgs/development/python-modules/<name>` | `python/pkgs/<name>` | `--python` |

`<xx>` is the lowercase two-letter prefix of the attribute name, so `SDL2_gfx`
is found under `sd/` and `R` under `r/`.

The script:

- copies the whole directory, preserving symlinks, so patch files come along
- renames `package.nix` to `default.nix`, and leaves both alone if both exist
- refuses to overwrite an existing destination unless given `--force`

It makes **no edits to the expression itself** — every cleanup in step 3 is
still manual.

**Packages outside `by-name`.** A handful still live under the old
`pkgs/development/...` trees, which the script does not know about. Copy those
by hand and rename `package.nix` yourself:

```bash
cp -r ../nixpkgs/pkgs/development/libraries/foo pkgs/foo
```

**Packages with multiple versions** belong in `pkgs-many/` and need to be
restructured into the `default.nix` / `variants.nix` / `generic.nix` layout
rather than copied — see the `mk-many-variants` skill.

### 3. Strip nixpkgs-only attributes

```nix
meta = {
  # maintainers = ...;  DELETE — not a recognised meta key here, fails check-meta
  # teams = ...;        DELETE — likewise
};

passthru = {
  # updateScript = gnome.updateScript { ... };  DELETE
  tests = { ... }; # KEEP
};
```

Also drop `doCheck = false;` if the expression sets it — that is already the
default across the package set. To keep a test suite, move it to
`passthru.tests` instead:

```nix
passthru.tests = {
  unittests = runUnitTests finalAttrs.finalPackage;
};
```

Build-system hooks are explicit here, so an imported expression usually needs
one added: `cmake.configurePhaseHook`, or `meson.configurePhaseHook` plus
`ninja`. See the `cmake` and `meson` skills.

### 4. Record what you disabled

Every feature turned off for a missing dependency gets a TODO naming the
dependency, so the package can be completed later without re-deriving why:

```nix
buildInputs = [
  zlib
  # TODO(corepkgs): Port openssl for TLS support
  # TODO(corepkgs): Port libxml2 for XML processing
];

configureFlags = [
  "--without-selinux"
  "--without-cap"
];
```

### 5. Validate

```bash
nix-instantiate -A example
nix-build -A example
./result/bin/example --version
```

Run `./ci/eval.sh` before committing to confirm nothing else in the set broke.
See the `validation` skill for the full procedure and error triage.

### 6. Add to top-level.nix only if needed

Packages in `pkgs/` and `pkgs-many/` are auto-registered by directory name. Add
an explicit entry **only** when the inputs deviate from what the expression
declares, or you need to override arguments or pass extra configuration.

## Example: straightforward package

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
    tag = "v${finalAttrs.version}";
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

  meta = {
    description = "Unprivileged sandboxing tool";
    homepage = "https://github.com/containers/bubblewrap";
    license = lib.licenses.lgpl2Plus;
    platforms = lib.platforms.linux;
  };
})
```

## Example: features disabled for missing dependencies

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
  };
})
```

## Common issues

**`Source path does not exist`** — the package is not in `by-name` (copy it by
hand), the name is not the attribute name, or `--nixpkgs-root` points at the
wrong checkout.

**`error: attribute 'somelib' missing`** — a dependency was never ported. Port
it, or drop the argument and disable the feature with a TODO.

**`configure: error: libfoo is required`** — the build system wants a dependency
you removed. Disable it explicitly, e.g. `configureFlags = [ "--without-foo" ];`.

**Nothing configures / no `Makefile` found** — the build-system hook was not
carried over. Add `cmake.configurePhaseHook` or `meson.configurePhaseHook`.

**`check-meta` rejects the package** — `meta.maintainers` or `meta.teams`
survived the cleanup.

## Checklist

- [ ] Dependencies checked with `nix-instantiate -A <dep>`
- [ ] Imported with `./scripts/import-from-nixpkgs.py` (or copied and renamed by hand)
- [ ] `meta.maintainers`, `meta.teams`, and `updateScript` removed
- [ ] Build-system configure hook added
- [ ] Missing dependencies recorded as `TODO(corepkgs)` comments
- [ ] License and any security patches preserved
- [ ] Validated per the `validation` skill, and `./ci/eval.sh` passes
