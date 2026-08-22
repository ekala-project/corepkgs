# GHC Binary 9.8.4 Segfault

## Problem

The GHC binary bootstrap package segfaults during `ghc-pkg recache` in its install phase:

```
/nix/store/.../setup: line 266: 52250 Segmentation fault (core dumped)
    "$out/bin/ghc-pkg" --package-db="$package_db" recache
```

**Derivation**: `/nix/store/fcn7jhrjjnjmsadqhaz675h1vdrpcyq1-ghc-binary-9.8.4.drv`

## Impact

This blocks the entire Haskell package chain, which cascades to:

- All Haskell packages (aeson, optparse-applicative, etc.)
- `asciidoc` (Haskell-based)
- `git` (needs asciidoc for docs)
- `nix` 2.31.2 (needs git for functional tests)
- **System toplevel** (needs nix)

Everything else in the EkaOS system builds successfully — this is the sole remaining blocker for a complete system build.

## Likely Cause

The binary GHC is being patchelf'd and the resulting `ghc-pkg` binary segfaults. This could be:
- Incompatible glibc version between the binary distribution and the corepkgs stdenv
- Patchelf breaking the binary (wrong interpreter, missing rpath entries)
- The binary GHC distribution expecting a different libc or libffi version

## Workaround Ideas

1. Use a different GHC binary version that's compatible with the current stdenv
2. Skip `ghc-pkg recache` during the binary bootstrap phase
3. Build git without asciidoc docs (`--without-asciidoc` or `NO_ASCIIDOC=1`)
4. Use a pre-built git from a binary cache instead of building from source
