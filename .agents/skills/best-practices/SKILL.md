---
name: best-practices
description: Review a package expression for best-practices compliance. Use when reviewing PRs or auditing existing packages — checks meta completeness, build-system idioms (cmakeEntries, mesonEntries, pyproject), dependency placement, and packaging conventions.
---

# Best Practices Review

Review a Nix package expression and report violations. Read the package file(s), then check every rule below. Report each finding with the line number and a short explanation.

## Meta Attributes

### Required Fields

Every package must have all three:

| Field | What to check |
|-------|---------------|
| `meta.description` | Present, non-empty, does not repeat the package name verbatim |
| `meta.license` | Present, uses `lib.licenses.*` (not a raw string) |
| `meta.platforms` | Present, uses `lib.platforms.*` |

### Recommended Fields

Flag as "recommended" (not error) if missing:

- `meta.homepage` — upstream project URL
- `meta.mainProgram` — for packages that install a binary

### Forbidden Fields

Flag as error if present:

- `meta.maintainers` or `meta.teams` — not a recognised key; fails `check-meta`

## Build-System Idioms

### CMake

- If `cmakeEntries`, `cmakeFlags`, or `cmakeBuildType` are used, `cmake.configurePhaseHook` **must** be in `nativeBuildInputs`. (Some builds use cmake as a dependency without the configure phase hook — that is fine.)
- Prefer `cmakeEntries` (attrset) over `cmakeFlags` (string list) for `-D` flags. Flag `cmakeFlags` with `-D` entries as "prefer cmakeEntries".

### Meson

- If `mesonEntries`, `mesonFlags`, or `mesonFeatures` are used, `meson.configurePhaseHook` **must** be in `nativeBuildInputs`.
- `ninja` **must** be in `nativeBuildInputs` when `meson.configurePhaseHook` is present.
- Prefer `mesonEntries` over `mesonFlags` for `-D` options. Flag `mesonFlags` with `-D` entries as "prefer mesonEntries".
- Prefer `mesonFeatures` for feature-type options (`enabled`/`disabled`/`auto`).

### Python

When using `buildPythonPackage`:

- `pyproject = true` should be set (flag legacy `format =` as "prefer pyproject")
- `build-system` should be present when `pyproject = true`
- `pythonImportsCheck` is recommended

### Rust

When using `buildRustPackage`:

- `cargoHash` must be present
- `meta.mainProgram` is recommended for binary crates

### Go

When using `buildGoModule`:

- `vendorHash` must be present
- `meta.mainProgram` is recommended for CLI tools

## Packaging Conventions

### Structural

- Use `finalAttrs` pattern — flag `rec {` as "prefer finalAttrs"
- Do **not** set `__structuredAttrs = true` — it is the default
- Do **not** set `doCheck = false` or `doInstallCheck = false` — they are defaults
- Do **not** set `meta.maintainers` or `meta.teams`

### Dependencies

- Build tools (compilers, code generators, pkg-config) belong in `nativeBuildInputs`, not `buildInputs`
- Libraries belong in `buildInputs`, not `nativeBuildInputs`
- Test-only deps belong in `checkInputs` or `nativeCheckInputs`
- `strictDeps = true` should be set when `depsBuildBuild` is used

### Sources

- `fetchFromGitHub`/`fetchFromGitLab` should use `tag`, not `rev` with a tag value
- Hash should be SRI format (`sha256-...`), not bare hex

### Testing

- Prefer `passthru.tests` over in-build `doCheck = true`
- Python packages: prefer `testPaths` over manual test phase

## Output Format

Group findings by severity:

```
## Errors
- line 12: missing `cmake.configurePhaseHook` in nativeBuildInputs
- line 30: `meta.maintainers` is forbidden — remove it

## Warnings
- line 8: `cmakeFlags` with -D entries — prefer `cmakeEntries` attrset
- line 25: `doCheck = false` is the default — remove redundant line

## Recommendations
- missing `meta.homepage`
- missing `meta.mainProgram` for binary package
```

If there are no findings in a severity group, omit that group. If the package is clean, say so.
