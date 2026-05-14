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
    rev = "v${finalAttrs.version}";
    hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
  };

  nativeBuildInputs = [
    meson
    meson.configurePhaseHook  # Required
    ninja                      # Required
    pkg-config
  ];

  mesonBuildType = "release";

  meta = {
    description = "Example Meson package";
    license = lib.licenses.mit;
    maintainers = [ ];
  };
})
```

## Essential Requirements

**Always include:**
- `meson.configurePhaseHook` - Sets up configure phase
- `ninja` - Required (Meson generates Ninja files)
- `pkg-config` - Usually needed for dependencies

**Specify build type:**
```nix
mesonBuildType = "release";  # or debug, debugoptimized, minsize
```

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

### Meson Flags

```nix
mesonFlags = [
  "-Ddocs=false"
  "-Dtests=false"
  "-Dsystemd=disabled"
  "-Dman=true"
];
```

**Feature options:** Use `enabled`/`disabled`/`auto`.

### Auto Features

```nix
mesonAutoFeatures = "auto";  # or enabled, disabled
```

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
mesonFlags = [ "-Doptional_feature=disabled" ];
```

**Disable subproject downloads:**
```nix
mesonFlags = [ "-Dwrap_mode=nodownload" ];
```

**Disable documentation:**
```nix
mesonFlags = [
  "-Ddocs=false"
  "-Dgtk_doc=false"
  "-Dman=false"
];
```

**Force library directory:**
```nix
mesonFlags = [ "-Dlibdir=lib" ];
```
