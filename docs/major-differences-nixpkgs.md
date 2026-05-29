# Major differences from Nixpkgs

Although there is desire to keep as aligned with Nixpkgs as possible, Ekapkgs
isn't obligated to retain poor UX paradigms either. In that vein, the following
changes differ significantly from whath one would expct with Nixpkgs.

## Evaluation behavior

- `~/.config/nix` is no longer respected for `config` or `overlays`
- `config.gitConfig` and `config.gitConfigFile` were removed
  - Globally altering git behavior should be done at the machine level

## Package paradigms

- setupHooks for build managers are now explicit and opt-in.
  - E.g. `meson.configurePhaseHook` now needs to be specified.
- `doCheck` now defaults to `false` across the package set.
  - Test suites are not executed as part of the main build by default.
  - This keeps the critical build path lean and avoids rebuilding the world
    when only a test-related input changes.
  - To run a package's tests, override with `doCheck = true` or evaluate the
    dedicated test derivation (e.g. `pkg.passthru.tests.*`).
- `buildPythonPackage` exposes a `testPaths` attribute for deferring test
  execution into a separate derivation.
  - `testPaths` is a list of files and/or directories (relative to the source
    root) that comprise the package's test suite. The typical case is
    `testPaths = [ "tests" ];`, but the list may include sibling helper
    modules, fixture data, root-level test scripts, or documentation files
    referenced by the test suite (e.g.
    `testPaths = [ "tests" "smartypants" "README.rst" ];`).
  - When `testPaths` is non-empty, an additional `test_src` output is
    produced containing just the listed paths (plus any root-level
    `conftest.py`, `pytest.ini`, `setup.cfg`, `pyproject.toml`, or `tox.ini`),
    and a `passthru.tests.python` derivation is auto-generated that runs the
    test suite against the installed package using the configured
    `nativeCheckInputs` / `checkInputs`.
  - The generated test derivation skips `configurePhase`, `buildPhase`, and
    `installPhase`. It runs only the `checkPhase` / `installCheckPhase`
    (plus any check hooks like `pytestCheckHook` that append to
    `preDistPhases`), against the installed package which is provided as a
    `nativeBuildInputs` entry. This avoids rebuilding the package just to
    run its tests.
  - This decouples test execution from the main build, allowing test failures
    or test-only dependency churn to avoid invalidating downstream consumers.
