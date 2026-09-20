---
name: rust
description: Package a Rust crate for corepkgs. Use when writing or editing a buildRustPackage derivation — covers cargoHash, cargoBuildFlags, checkFlags, shell completions, and cross-compilation.
---

# Rust Packages

Rust packages live in `pkgs/<name>/default.nix` using `rustPlatform.buildRustPackage`.

## Minimal Example

```nix
{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "example";
  version = "1.0.0";

  src = fetchFromGitHub {
    owner = "example";
    repo = "example";
    tag = "v${finalAttrs.version}";
    hash = "sha256-...";
  };

  cargoHash = "sha256-...";

  meta = {
    description = "Example Rust tool";
    license = lib.licenses.mit;
    mainProgram = "example";
  };
})
```

## Essential Attributes

- `cargoHash` — SRI hash of vendored Cargo dependencies. Set to `lib.fakeHash` to get the correct value from the build error.
- `cargoBuildFlags` — extra flags passed to `cargo build` (e.g., `[ "--package" "foo" "--bin" "foo" ]` for workspaces)
- `cargoTestFlags` — extra flags passed to `cargo test`
- `checkFlags` — flags appended to the test command. Use `--skip` to disable specific tests:
  ```nix
  checkFlags = [
    "--skip=tests::network_test"
    "--skip=tests::flaky_timing"
  ];
  ```

## Auto-Generated Tests

`buildRustPackage` automatically provides `passthru.tests.build` — a variant that re-runs with `doCheck = true`. User-supplied `passthru.tests` entries merge alongside it.

## Native Dependencies

Rust crates that link C libraries need explicit inputs:

```nix
nativeBuildInputs = [ pkg-config ];
buildInputs = [ openssl zlib ];
```

## Shell Completions

```nix
nativeBuildInputs = [ installShellFiles ];

postInstall = ''
  installShellCompletion --cmd example \
    --bash <($out/bin/example completions bash) \
    --fish <($out/bin/example completions fish) \
    --zsh <($out/bin/example completions zsh)
'';
```

Guard with build platform check when cross-compiling:

```nix
postInstall = lib.optionalString (stdenv.hostPlatform.emulatorAvailable buildPackages) ''
  installShellCompletion ...
'';
```

## Complete Example

```nix
{
  lib,
  rustPlatform,
  fetchFromGitHub,
  pkg-config,
  erlang,
  git,
}:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "gleam";
  version = "1.18.1";

  src = fetchFromGitHub {
    owner = "gleam-lang";
    repo = "gleam";
    tag = "v${finalAttrs.version}";
    hash = "sha256-...";
  };

  cargoHash = "sha256-...";

  nativeBuildInputs = [ pkg-config erlang ];
  nativeCheckInputs = [ git ];

  checkFlags = [
    "--skip=tests::all_files_have_copyright_notice"
    "--skip=tests::echo::"
  ];

  meta = {
    description = "Statically typed language for the Erlang VM";
    homepage = "https://gleam.run/";
    license = lib.licenses.asl20;
    mainProgram = "gleam";
  };
})
```
