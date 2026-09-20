---
name: go
description: Package a Go module for corepkgs. Use when writing or editing a buildGoModule derivation — covers vendorHash, ldflags, subPackages, checkFlags, and versionCheckHook.
---

# Go Packages

Go packages live in `pkgs/<name>/default.nix` using `buildGoModule`.

## Minimal Example

```nix
{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:

buildGoModule (finalAttrs: {
  pname = "example";
  version = "1.0.0";

  src = fetchFromGitHub {
    owner = "example";
    repo = "example";
    tag = "v${finalAttrs.version}";
    hash = "sha256-...";
  };

  vendorHash = "sha256-...";

  meta = {
    description = "Example Go tool";
    license = lib.licenses.mit;
    mainProgram = "example";
  };
})
```

## Essential Attributes

- `vendorHash` — SRI hash of vendored Go modules. Set to `lib.fakeHash` to get the correct value from the build error. Use `null` when the repo vendors dependencies in-tree.
- `ldflags` — linker flags, commonly used for version injection:
  ```nix
  ldflags = [
    "-s" "-w"
    "-X main.Version=v${finalAttrs.version}"
  ];
  ```
- `subPackages` — limit which packages get built (defaults to all):
  ```nix
  subPackages = [ "cmd/mytool" ];
  ```
- `checkFlags` — flags for `go test`. Use `-skip` to disable specific tests:
  ```nix
  checkFlags = [ "-skip" "TestNetwork" ];
  ```

## Auto-Generated Tests

`buildGoModule` automatically provides `passthru.tests.build` — a variant that re-runs with `doCheck = true`. User-supplied `passthru.tests` entries merge alongside it.

## Version Check

```nix
nativeInstallCheckInputs = [ versionCheckHook ];
versionCheckProgramArg = "--version";
doInstallCheck = true;
```

## Shell Completions

```nix
nativeBuildInputs = [ installShellFiles ];

postInstall = ''
  installShellCompletion --cmd example \
    --bash <($out/bin/example completion bash) \
    --fish <($out/bin/example completion fish) \
    --zsh <($out/bin/example completion zsh)
'';
```

## Complete Example

```nix
{
  lib,
  buildGoModule,
  fetchFromGitHub,
  installShellFiles,
  versionCheckHook,
}:

buildGoModule (finalAttrs: {
  pname = "age";
  version = "1.3.1";

  src = fetchFromGitHub {
    owner = "FiloSottile";
    repo = "age";
    tag = "v${finalAttrs.version}";
    hash = "sha256-...";
  };

  vendorHash = "sha256-...";

  ldflags = [
    "-s" "-w"
    "-X main.Version=v${finalAttrs.version}"
  ];

  nativeBuildInputs = [ installShellFiles ];

  preInstall = ''
    installManPage doc/*.1
  '';

  nativeInstallCheckInputs = [ versionCheckHook ];
  versionCheckProgramArg = "--version";
  doInstallCheck = true;

  checkFlags = [ "-skip" "TestScript/plugin" ];

  meta = {
    description = "Modern encryption tool with small explicit keys";
    homepage = "https://age-encryption.org/";
    license = lib.licenses.bsd3;
    mainProgram = "age";
  };
})
```
