# Python Package Build Issues

Python packages fail for several distinct reasons after version bumps. The fix depends on the failure mode.

## Build system changes

Upstream projects frequently switch build backends between releases.

### setuptools to hatchling

```
ERROR Backend subprocess exited when trying to invoke get_requires_for_build_wheel
```

The package switched from `setuptools` to `hatchling` (or vice versa). Update `build-system`:

```nix
# Before
build-system = [ setuptools setuptools-scm ];

# After
build-system = [ hatchling hatch-vcs ];
```

Also update function arguments to import the new build backend and remove the old one.

### setuptools-scm version pin

```
ERROR setuptools_scm._overrides:version ... is not in range ...
```

The `pyproject.toml` may pin a `setuptools-scm` version range incompatible with what's in core-pkgs. Patch it out:

```nix
postPatch = ''
  substituteInPlace pyproject.toml \
    --replace-fail ', "setuptools-scm>=8,<11"' ""
'';
```

### Unwanted build dependencies

When a new version adds an optional dependency that isn't available, use `pythonRemoveDeps`:

```nix
pythonRemoveDeps = [ "sphinx-notfound-page" ];
```

## Cython version pin

```
ERROR Cython version mismatch
```

Upstream may pin a Cython minimum version. Relax the pin:

```nix
postPatch = ''
  substituteInPlace pyproject.toml \
    --replace-fail 'Cython>=3.2.4' 'Cython'
'';
```

## Missing conftest.py

```
FileNotFoundError: conftest.py
```

Upstream may have removed or restructured test files. Update `postInstall` to only copy files that still exist:

```nix
# Before
postInstall = ''
  mkdir $testout
  cp -R conftest.py tests $testout
'';

# After — conftest.py was removed upstream
postInstall = ''
  mkdir $testout
  cp -R tests $testout
'';
```

## Coherent-licensed and other new pyproject plugins

```
ERROR Failed to parse pyproject.toml: unknown key "coherent.licensed"
```

Remove the reference with `substituteInPlace`:

```nix
postPatch = ''
  substituteInPlace pyproject.toml \
    --replace-fail '"coherent.licensed",' ""
'';
```

## Transitive dependency failures

```
error: Build failed due to failed dependency
```

The package itself builds fine, but one of its Python dependencies fails. This is **not fixable** in the failing package's Nix file. Fix the broken dependency first, then retry.
