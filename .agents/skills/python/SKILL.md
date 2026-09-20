---
name: python
description: Package a Python project for corepkgs. Use when writing or editing python/pkgs/<name>/default.nix — covers buildPythonPackage, pyproject, build-system, dependencies, testPaths, pytestCheckHook, disabledTests, and pythonImportsCheck.
---

# Python Packages

Python packages live in `python/pkgs/<name>/default.nix`.

## Minimal Example

```nix
{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  setuptools,
  pytestCheckHook,
}:

buildPythonPackage (finalAttrs: {
  pname = "example";
  version = "1.0.0";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "example";
    repo = "example";
    tag = "v${finalAttrs.version}";
    hash = "sha256-...";
  };

  build-system = [ setuptools ];

  nativeCheckInputs = [ pytestCheckHook ];
  testPaths = [ "tests" ];

  pythonImportsCheck = [ "example" ];

  meta = {
    description = "Example Python library";
    license = lib.licenses.mit;
  };
})
```

## Essential Attributes

- `pyproject = true;` — use pyproject.toml-based build (preferred over legacy `format = "setuptools"`)
- `build-system` — list of build backends: `setuptools`, `hatchling`, `flit-core`, `poetry-core`, `maturin`, `pdm-backend`, `setuptools-scm`
- `dependencies` — runtime Python dependencies
- `optional-dependencies` — attrset of extras groups
- `disabled = pythonOlder "3.9";` — skip on older interpreters

## Testing

`testPaths` auto-generates `passthru.tests.python` and a `test_src` output:

```nix
nativeCheckInputs = [ pytestCheckHook ];
testPaths = [ "tests" ];
```

For suites needing extra files: `testPaths = [ "tests" "src/helpers" "README.rst" ];`

These attributes are forwarded automatically to the test derivation:
- `disabledTests`, `disabledTestPaths`, `enabledTestPaths`
- `pytestFlags`, `pytestFlagsArray`, `unittestFlagsArray`
- `preCheck`, `postCheck`, `preInstallCheck`, `postInstallCheck`

### Disabling Tests

```nix
disabledTests = [
  "test_network_access"     # requires internet
  "test_flaky_timing"       # non-deterministic
];

disabledTestPaths = [
  "tests/integration/"      # needs running service
];
```

Platform-conditional disabling:

```nix
disabledTests = [
  "test_basic"
] ++ lib.optionals stdenv.hostPlatform.isDarwin [
  "test_linux_specific"
];
```

### Manual `tests.nix` (Fallback)

When `testPaths` is not suitable (e.g., circular dependencies with pytest):

```nix
passthru.tests = {
  pytest = callPackage ./tests.nix { };
};
```

## Smoke Checks

`pythonImportsCheck` runs automatically during `buildPythonPackage` — no need to enable `doInstallCheck`:

```nix
pythonImportsCheck = [ "requests" "requests.auth" ];
```

## Removing Unwanted Build Dependencies

When upstream pins a dependency unavailable in corepkgs:

```nix
pythonRemoveDeps = [ "some-unavailable-dep" ];
```

## Complete Example

```nix
{
  lib,
  stdenv,
  buildPythonPackage,
  fetchFromGitHub,
  pythonOlder,
  setuptools,
  certifi,
  charset-normalizer,
  idna,
  urllib3,
  pysocks,
  pytest-mock,
  pytestCheckHook,
}:

buildPythonPackage (finalAttrs: {
  pname = "requests";
  version = "2.34.2";
  pyproject = true;

  disabled = pythonOlder "3.9";

  src = fetchFromGitHub {
    owner = "psf";
    repo = "requests";
    tag = "v${finalAttrs.version}";
    hash = "sha256-...";
  };

  build-system = [ setuptools ];

  dependencies = [
    certifi
    charset-normalizer
    idna
    urllib3
  ];

  optional-dependencies = {
    socks = [ pysocks ];
  };

  nativeCheckInputs = [
    pytest-mock
    pytestCheckHook
  ] ++ finalAttrs.optional-dependencies.socks;

  disabledTests = [
    "test_redirecting_to_bad_url"       # requires network
  ] ++ lib.optionals stdenv.hostPlatform.isDarwin [
    "test_basic_response"               # Fatal Python error on aarch64-darwin
  ];

  testPaths = [ "tests" ];

  pythonImportsCheck = [ "requests" ];

  meta = {
    description = "HTTP library for Python";
    homepage = "https://docs.python-requests.org/";
    license = lib.licenses.asl20;
  };
})
```
