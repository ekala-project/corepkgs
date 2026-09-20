# core-pkgs Agent Guide

## Commit Conventions

- **New packages:** `<pkg>: init at <version>`
- **Version updates:** `<pkg>: <old version> -> <new version>`
- **ekaos modules:** `ekaos/<module>: init | <succinct message>`
- **Do not** add AI attribution (e.g., `Co-Authored-By`) to commit messages

## Writing Packages

Read the guide matching the package's build system or language.

| Task | Guide |
|------|-------|
| Nix expression basics (stdenv.mkDerivation, finalAttrs, meta, deps, fetchers, patches, outputs, passthru, package organization, top-level.nix) | [packaging](.agents/skills/packaging/SKILL.md) |
| Python (buildPythonPackage, pyproject, build-system, testPaths, disabledTests, pythonImportsCheck) | [python](.agents/skills/python/SKILL.md) |
| Rust (buildRustPackage, cargoHash, cargoBuildFlags, checkFlags) | [rust](.agents/skills/rust/SKILL.md) |
| Go (buildGoModule, vendorHash, ldflags, subPackages) | [go](.agents/skills/go/SKILL.md) |
| CMake project (cmake.configurePhaseHook, cmakeEntries) | [cmake](.agents/skills/cmake/SKILL.md) |
| Meson project (meson.configurePhaseHook, mesonEntries, mesonFeatures) | [meson](.agents/skills/meson/SKILL.md) |
| Multi-version package in pkgs-many/ (mkManyVariants, variants.nix) | [mk-many-variants](.agents/skills/mk-many-variants/SKILL.md) |
| Porting from nixpkgs (copy, strip maintainers/updateScript, TODO missing deps) | [porting](.agents/skills/porting/SKILL.md) |
| Bash phases under structured attrs (array iteration, env attrset, substituteAll) | [structured-attrs](.agents/skills/structured-attrs/SKILL.md) |
| ekaos service module (services.*, cross-platform interface, systemd/launchd/runit) | [services](services/AGENTS.md) |

## Fixing Build Failures

Read the guide matching the error symptom. Start with [validation](.agents/skills/validation/SKILL.md) for the eval/build/format workflow.

| Symptom | Guide |
|---------|-------|
| Eval or build error — validation workflow, nix-instantiate, nix-build, nix fmt | [validation](.agents/skills/validation/SKILL.md) |
| "Reversed patch" / "Hunk FAILED" — obsolete fetchpatch entries after version bump | [obsolete-patches](docs/common-issues/obsolete-patches.md) |
| Python build-system switch, setuptools-scm pin, Cython conflict, missing conftest.py | [python-issues](docs/common-issues/python-packages.md) |
| CMake install path errors, feature flag renames between versions | [cmake-issues](docs/common-issues/cmake-packages.md) |
| cargoHash / vendorHash mismatch, go.mod version pin | [rust-go-issues](docs/common-issues/rust-packages.md) |
| -Werror failures, missing headers, new compiler warnings | [compiler-errors](docs/common-issues/compiler-errors.md) |
| "Build failed due to failed dependency" — transitive breakage, fix the dep first | [dependency-failures](docs/common-issues/dependency-failures.md) |
