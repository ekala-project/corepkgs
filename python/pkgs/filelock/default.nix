{
  lib,
  buildPythonPackage,
  fetchPypi,
  hatch-vcs,
  hatchling,
  pytest-asyncio,
  pytest-mock,
  pytest-timeout,
  pytestCheckHook,
}:

buildPythonPackage (finalAttrs: {
  pname = "filelock";
  version = "3.29.6";
  pyproject = true;

  src = fetchPypi {
    inherit (finalAttrs) pname version;
    hash = "sha256-iVxTLvP07wSXK5RGqMTikxpcOZ/zxL5Mk2nyY5uA95M=";
  };

  build-system = [
    hatch-vcs
    hatchling
  ];

  nativeCheckInputs = [
    pytest-asyncio
    pytest-mock
    pytest-timeout
    pytestCheckHook
  ];

  testPaths = [ "tests" ];

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

  };
})
