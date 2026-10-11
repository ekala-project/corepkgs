---
name: go
description: Package a Go module for corepkgs. Use when writing or editing a buildGoModule derivation — covers vendorHash, ldflags, subPackages, tags, env.CGO_ENABLED, proxyVendor, shell completions, and pinning a Go version.
---

# Go Packages

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
    hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
  };

  vendorHash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";

  meta = {
    description = "Example Go tool";
    license = lib.licenses.mit;
    mainProgram = "example";
  };
})
```

## Essential Requirements

**Always use `buildGoModule`** (aliased from `go.buildModule`). It handles vendor fetching, build phases, and automatic `passthru.tests.build`.

## Pinning a Go Version

When upstream requires a specific Go release, use the versioned builder:

```nix
{ go, ... }:

go.v1_26.buildModule (finalAttrs: {
  # ...
})
```

Available as `go.v1_XX.buildModule` for each Go version in `pkgs-many/go/`. Only pin when necessary (e.g., upstream uses APIs removed in a newer Go).

## Common Patterns

### Vendor Hash

- `vendorHash` — SRI hash of vendored Go modules. Set to `lib.fakeHash` to get the correct value from the build error.
- `vendorHash = null` — when the source tree already contains a `vendor/` directory.

### Proxy Vendor

Use `proxyVendor = true` when the vendor hash differs between Linux and Darwin (common with C dependencies in vendored modules):

```nix
proxyVendor = true;  # hash mismatch between Linux and Darwin
vendorHash = "sha256-...";
```

### ldflags

Linker flags, commonly used for stripping debug info and injecting version strings:

```nix
ldflags = [
  "-s" "-w"
  "-X main.Version=v${finalAttrs.version}"
];
```

Multiple `-X` flags for complex version info:

```nix
ldflags = [
  "-s" "-w"
  "-X github.com/org/repo/pkg.Version=v${finalAttrs.version}"
  "-X github.com/org/repo/pkg.Commit=unknown"
];
```

Dynamic ldflags via `preBuild`:

```nix
ldflags = [ "-s" "-w" "-X main.Version=v${finalAttrs.version}" ];

preBuild = ''
  ldflags+=" -X main.Date=$(cat SOURCE_DATE_EPOCH)"
'';
```

The framework automatically appends `-buildid=` to ldflags.

### CGO

CGO is controlled via `env.CGO_ENABLED`. It defaults to the Go toolchain's value.

```nix
# Disable CGO (pure Go, no C dependencies)
env.CGO_ENABLED = 0;

# Enable CGO (links C libraries)
env.CGO_ENABLED = 1;
```

Platform-conditional CGO:

```nix
env.CGO_ENABLED = if stdenv.hostPlatform.isDarwin then 1 else 0;
```

### subPackages

Limit which packages get built (defaults to scanning all):

```nix
subPackages = [ "cmd/mytool" ];
```

Common patterns:

```nix
subPackages = [ "." ];                    # Root package only
subPackages = [ "cmd/foo" "cmd/bar" ];    # Multiple binaries
subPackages = [ "cmd/*" ];                # Glob
```

### tags

Build tags for conditional compilation:

```nix
tags = [ "release" ];
```

Platform-conditional tags:

```nix
tags = lib.optionals (fuse3 != null) [ "fuse3" ]
  ++ lib.optionals enableCmount [ "cmount" ];
```

### checkFlags

Flags for `go test`. Use `-skip` to disable specific tests:

```nix
checkFlags = [ "-skip" "TestNetwork" ];
```

### env

Additional environment variables via the `env` attrset (exported under structured attrs):

```nix
env = {
  CGO_ENABLED = 0;
  GOFLAGS = [ "-trimpath" ];
};
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

postInstall = lib.optionalString (stdenv.buildPlatform.canExecute stdenv.hostPlatform) ''
  installShellCompletion --cmd example \
    --bash <($out/bin/example completion bash) \
    --fish <($out/bin/example completion fish) \
    --zsh  <($out/bin/example completion zsh)
'';
```

The `canExecute` guard is needed for cross-compilation — the built binary may not be runnable on the build platform.

## Complete Example

```nix
{
  lib,
  stdenv,
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
