{
  lib,
  buildPythonPackage,
  pythonOlder,
  fetchFromGitHub,
  setuptools,
  packaging,
  pytest,
  pytestCheckHook,
}:

buildPythonPackage (finalAttrs: {
  pname = "pytest-rerunfailures";
  version = "16.0.1";
  pyproject = true;

  disabled = pythonOlder "3.9";

  src = fetchFromGitHub {
    owner = "pytest-dev";
    repo = "pytest-rerunfailures";
    tag = finalAttrs.version;
    hash = "sha256-4/BgvfVcs7MdULlhafZypNzzag4ITALStHI1tIoAPL4=";
  };

  build-system = [ setuptools ];

  buildInputs = [ pytest ];

  dependencies = [ packaging ];

  nativeCheckInputs = [ pytestCheckHook ];

  testPaths = [ "tests" ];

  pythonImportsCheck = [ "pytest_rerunfailures" ];

  meta = {
    description = "Pytest plugin to re-run tests to eliminate flaky failures";
    homepage = "https://github.com/pytest-dev/pytest-rerunfailures";
    changelog = "https://github.com/pytest-dev/pytest-rerunfailures/blob/${finalAttrs.src.tag}/CHANGES.rst";
    license = lib.licenses.mpl20;

  };
})
