# Bootstrap Files

Bootstrap files are the pre-built seed binaries needed to create the first
stdenv. They consist of two artifacts per target:

- **`bootstrap-tools.tar.xz`** — gcc, binutils, glibc/musl, coreutils, bash,
  and other tools needed to compile everything from source.
- **`busybox`** — a statically-linked minimal busybox used to unpack the
  tarball (it's the only binary required from outside the Nix store).

## Uploading new bootstrap files

```bash
# Build and upload for the current platform:
./upload-bootstrap.bash

# Build for specific targets:
./upload-bootstrap.bash --targets=x86_64-unknown-linux-gnu,aarch64-unknown-linux-gnu

# Dry run (build only, inspect artifacts, no upload):
./upload-bootstrap.bash --dry-run

# Custom release tag:
./upload-bootstrap.bash --tag=bootstrap-2026-08-24
```

The script will:
1. Build `freshBootstrapTools.build` for each target
2. Create a GitHub release on `ekala-project/corepkgs`
3. Upload the artifacts as release assets
4. Update the `.nix` files under `stdenv/linux/bootstrap-files/` with new
   URLs and hashes

After running, commit and push the updated `.nix` files.

## Requirements

- `nix` with flakes
- `gh` (GitHub CLI), authenticated with write access to the repo

## Adding a new target

1. Ensure the target can build `freshBootstrapTools.build` (may require
   `pkgsCross` support for cross-built targets).
2. Add the target triple to the appropriate list in `upload-bootstrap.bash`
   (`NATIVE_TARGETS` or `CROSS_TARGETS`).
3. Run `./upload-bootstrap.bash --targets=<new-target>`.
4. The script will create the `.nix` file automatically.
