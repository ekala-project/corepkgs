# Rust and Go Package Build Issues

## Rust: cargoHash mismatch

After updating a Rust package's version and source hash, the `cargoHash` must also be updated since the `Cargo.lock` file changes.

### Symptom

```
hash mismatch in fixed-output derivation '/nix/store/...-...-vendor.tar.gz':
  specified: sha256-OLD...
  got:       sha256-NEW...
```

### Fix

Replace the old `cargoHash` with the correct one from the error message:

```nix
cargoHash = "sha256-NEW...";
```

If the updater tool handles this automatically but fails, the error output will contain the correct hash.

## Go: version pin in go.mod

Go packages may pin a Go version in `go.mod` that's newer than what's available in core-pkgs.

### Symptom

```
go: go.mod requires go >= 1.26.4 (running go 1.26.3)
```

### Fix

Patch the `go.mod` to accept the available Go version:

```nix
postPatch = ''
  substituteInPlace go.mod --replace-fail 'go 1.26.4' 'go 1.26.3'
'';
```

Or switch to a pinned Go builder if one is available:

```nix
# Before
buildGoModule

# After — use a specific Go version
buildGo126Module
```

## Go: vendorHash mismatch

Same pattern as `cargoHash` — after version bump, `vendorHash` needs updating. Replace with the hash from the error message.
