---
name: meson
description: Package a Meson/Ninja project for corepkgs. Use when a source tree has a meson.build — covers mesonFlags, auto features, cross-compilation, and diagnosing Meson setup failures.
---

# Meson Build System

## Minimal Example

```nix
{
  lib,
  stdenv,
  fetchFromGitHub,
  meson,
  ninja,
  pkg-config,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "example";
  version = "1.0.0";

  src = fetchFromGitHub {
    owner = "example";
    repo = "example";
    tag = "v${finalAttrs.version}";
    hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
  };

  nativeBuildInputs = [
    meson
    meson.configurePhaseHook  # Required
    ninja                      # Required
    pkg-config
  ];

  meta = {
    description = "Example Meson package";
    license = lib.licenses.mit;
  };
})
```

## Essential Requirements

**Always include:**
- `meson.configurePhaseHook` - Sets up configure phase
- `ninja` - Required (Meson generates Ninja files)
- `pkg-config` - Usually needed for dependencies

## Common Patterns

### With Dependencies

```nix
nativeBuildInputs = [
  meson
  meson.configurePhaseHook
  ninja
  pkg-config
];

buildInputs = [
  glib
  libcap
];
```

### Meson Entries (Preferred)

Use `mesonEntries` to specify Meson `-D` options as a structured attrset.
Booleans are automatically converted to `true`/`false`.

```nix
mesonEntries = {
  docs = false;
  man = true;
  wrap_mode = "nodownload";
};
```

### Meson Features

Use `mesonFeatures` for Meson `feature` type options (those that accept
`enabled`/`disabled`/`auto`). Booleans are automatically converted to
`enabled`/`disabled`.

```nix
mesonFeatures = {
  introspection = withIntrospection;
  tests = false;
};
```

Both `mesonEntries` and `mesonFeatures` are merged into the same set of `-D`
flags. If a key appears in both, `mesonFeatures` wins.

### Meson Flags (Legacy)

`mesonFlags` still works for string-based flags and non-`-D` flags:

```nix
mesonFlags = [
  "-Ddocs=false"
  "-Dtests=false"
  "-Dsystemd=disabled"
  "-Dman=true"
];
```

Both can be used together. `mesonFlags` values override `mesonEntries` for the
same key (meson uses last-wins for `-D` flags). Use `mesonFlags` for non-`-D`
flags like `--cross-file`.

### Cross-Compilation

```nix
strictDeps = true;

nativeBuildInputs = [ meson meson.configurePhaseHook ninja pkg-config ];
buildInputs = [ glib ];
depsBuildBuild = [ pkg-config ];
```

## Troubleshooting

**Dependency not found:**
```nix
mesonFeatures = { optional_feature = false; };
```

**Disable subproject downloads:**
```nix
mesonEntries = { wrap_mode = "nodownload"; };
```

**Disable documentation:**
```nix
mesonEntries = {
  docs = false;
  gtk_doc = false;
  man = false;
};
```

**Force library directory:**
```nix
mesonEntries = { libdir = "lib"; };
```
