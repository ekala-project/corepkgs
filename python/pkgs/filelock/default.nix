{
  lib,
  buildPythonPackage,
  fetchPypi,
  hatch-fancy-pypi-readme,
  hatch-vcs,
  hatchling,
  pytest-asyncio,
  pytest-mock,
  pytest-timeout,
  pytestCheckHook,
}:

buildPythonPackage (finalAttrs: {
  pname = "filelock";
  version = "4.2.7";
  pyproject = true;

  src = fetchPypi {
    inherit (finalAttrs) pname version;
    hash = "sha256-Mfb346i28L2JEU0wxdUhjqHPtj5cSqaVt1WTFKIJvH8=";
  };

  build-system = [
    hatch-fancy-pypi-readme
    hatch-vcs
    hatchling
  ];

  nativeCheckInputs = [
    pytest-asyncio
    pytest-mock
    pytest-timeout
    pytestCheckHook
  ];

  testPaths = [
    "tests"
    "tasks" # capabilities module needed by conftest.py
  ];

  pythonImportsCheck = [ "filelock" ];

  disabledTestPaths = [
    # Circular dependency with virtualenv
    "tests/test_virtualenv.py"
  ];

  meta = {
    changelog = "https://github.com/tox-dev/py-filelock/releases/tag/${finalAttrs.version}";
    description = "Platform independent file lock for Python";
    homepage = "https://github.com/benediktschmitt/py-filelock";
    license = lib.licenses.unlicense;
    platforms = lib.platforms.all;
  };
})
