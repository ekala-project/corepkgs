{
  lib,
  stdenv,
  build,
  buildPythonPackage,
  fetchFromGitHub,
  flit-core,
  filelock,
  packaging,
  pyproject-hooks,
  pytest-mock,
  pytest-rerunfailures,
  pytest-xdist,
  pytestCheckHook,
  pythonOlder,
  setuptools,
  tomli,
  virtualenv,
  wheel,
}:

buildPythonPackage (finalAttrs: {
  pname = "build";
  version = "1.3.0";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "pypa";
    repo = "build";
    tag = finalAttrs.version;
    hash = "sha256-w2YKQzni8e6rpnQJH2J0bHzRigjWOlWiI8Po5d3ZqS8=";
  };

  build-system = [ flit-core ];

  pythonRemoveDeps = [ "importlib-metadata" ];

  dependencies = [
    packaging
    pyproject-hooks
  ]
  ++ lib.optionals (pythonOlder "3.11") [ tomli ];

  passthru.tests = {
    pytest = buildPythonPackage {
      pname = "${finalAttrs.pname}-pytest";
      inherit (finalAttrs) src version;
      pyproject = false;

      dontBuild = true;
      dontInstall = true;

      nativeCheckInputs = [
        build
        filelock
        pytest-mock
        pytest-rerunfailures
        pytest-xdist
        pytestCheckHook
        setuptools
        virtualenv
        wheel
      ];

      pytestFlags = [
        "-Wignore::DeprecationWarning"
      ];

      __darwinAllowLocalNetworking = true;

      disabledTests = [
        # Tests often fail with StopIteration
        "test_isolat"
        "test_default_pip_is_never_too_old"
        "test_build"
        "test_with_get_requires"
        "test_init"
        "test_output"
        "test_wheel_metadata"
        # Tests require network access to run pip install
        "test_verbose_output"
        "test_requirement_installation"
      ]
      ++ lib.optionals stdenv.hostPlatform.isDarwin [
        # Expects Apple's Python and its quirks
        "test_can_get_venv_paths_with_conflicting_default_scheme"
      ];
    };
  };

  pythonImportsCheck = [ "build" ];

  meta = {
    mainProgram = "pyproject-build";
    description = "Simple, correct PEP517 package builder";
    longDescription = ''
      build will invoke the PEP 517 hooks to build a distribution package. It
      is a simple build tool and does not perform any dependency management.
    '';
    homepage = "https://github.com/pypa/build";
    changelog = "https://github.com/pypa/build/blob/${finalAttrs.src.tag}/CHANGELOG.rst";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
  };
})
