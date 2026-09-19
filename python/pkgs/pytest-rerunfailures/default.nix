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

  disabledTests = [
    # flaky: rerun fixture outcome assertions differ
    "test_run_session_teardown_once_after_reruns"
    "test_rerun_on_setup_class_with_error_with_reruns"
    "test_rerun_on_class_scope_fixture_with_error_with_reruns"
    "test_rerun_on_module_fixture_with_reruns"
    "test_rerun_on_session_fixture_with_reruns"
  ];

  pythonImportsCheck = [ "pytest_rerunfailures" ];

  meta = {
    description = "Pytest plugin to re-run tests to eliminate flaky failures";
    homepage = "https://github.com/pytest-dev/pytest-rerunfailures";
    changelog = "https://github.com/pytest-dev/pytest-rerunfailures/blob/${finalAttrs.src.tag}/CHANGES.rst";
    license = lib.licenses.mpl20;

  };
})
