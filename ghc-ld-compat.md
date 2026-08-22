# GHC 9.8.4 / binutils 2.44 Linker Incompatibility

## Problem

When compiling Haskell packages with GHC 9.8.4 binary, the system linker
(binutils 2.44 `ld`) fails with:

```
ld: /build/ghc471_0/ghc_188.o: bad reloc symbol index (0x5153 >= 0x4c52)
ld: failed to set dynamic section sizes: bad value
```

This causes `ld failed in phase 'Merge objects'` for packages like `aeson`.

## Cause

GHC 9.8.x produces object files with relocations that are incompatible
with binutils 2.44's `ld`. This is a known class of issue between GHC
and newer binutils versions.

## Fix Options

1. **Use `ld.gold` instead of `ld`** — set `--with-ld=ld.gold` in GHC's settings
   or set `ld-options: -fuse-ld=gold` in cabal configurations
2. **Use `ld.mold` or `ld.lld`** — alternative linkers that handle GHC's
   relocations correctly
3. **Downgrade binutils** to a version compatible with GHC 9.8.x
4. **Upgrade to GHC 9.10+** which may produce compatible object files
