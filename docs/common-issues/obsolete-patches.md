# Obsolete Patches

The most common build failure after a version bump. Patches applied via `fetchpatch` or `fetchurl` become obsolete when upstream incorporates the fix.

## Symptoms

### Reversed patch (already applied upstream)

```
Reversed (or previously applied) patch detected!  Assume -R? [n]
Apply anyway? [n]
Skipping patch.
1 out of 1 hunk ignored
```

### Patch no longer applies (context changed)

```
applying patch /nix/store/...-fix-something.patch
patching file src/foo.c
Hunk #1 FAILED at 25.
1 out of 1 hunk FAILED -- saving rejects to file src/foo.c.rej
```

## Fix

Remove the obsolete patch from the `patches` list. Also remove the corresponding `fetchpatch`/`fetchurl` call and any now-unused function arguments.

### Before

```nix
{
  lib,
  stdenv,
  fetchFromGitHub,
  fetchpatch,  # <-- remove if no longer used
}:

stdenv.mkDerivation {
  # ...
  patches = [
    (fetchpatch {
      name = "fix-something.patch";
      url = "https://github.com/owner/repo/commit/abc123.patch";
      hash = "sha256-...";
    })
  ];
};
```

### After

```nix
{
  lib,
  stdenv,
  fetchFromGitHub,
  # fetchpatch removed — no longer needed
}:

stdenv.mkDerivation {
  # ...
  # patches list removed entirely, or other patches kept
};
```

## Partial patch failure

When a multi-hunk patch has some hunks that apply and some that fail, the patch needs to be regenerated against the new source version or split into the hunks that are still relevant. If the issue the patch fixed is upstream, remove the entire patch.

## Patches defined outside the package file

Some packages inherit patches from a shared expression (e.g., LLVM packages, elogind). In these cases, the patch may not appear in the package's own `patches = [...]` list. Check parent expressions or `generic.nix` files for the patch definitions.
