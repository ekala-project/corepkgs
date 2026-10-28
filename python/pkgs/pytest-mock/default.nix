{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  pytest,
  pytest-asyncio,
  pytestCheckHook,
  setuptools,
  setuptools-scm,
}:

buildPythonPackage (finalAttrs: {
  pname = "pytest-mock";
  version = "3.17.0";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "pytest-dev";
    repo = "pytest-mock";
    tag = "v${finalAttrs.version}";
    hash = "sha256-scJGIydFhvg9R6BPjlWkrpAaYvSuQMj7yQm3gwvRGCQ=";
  };

  build-system = [
    setuptools
    setuptools-scm
  ];

  buildInputs = [ pytest ];

  nativeCheckInputs = [
    pytest-asyncio
    pytestCheckHook
  ];

  testPaths = [ "tests" ];

  disabledTests = [
    # pytest internals changed; _pytest.assertion.util API mismatch
    "test_assert_called_kwargs_with_introspection"
    "test_assert_called_args_with_introspection"
  ];

  pythonImportsCheck = [ "pytest_mock" ];

  meta = {
    description = "Thin wrapper around the mock package for easier use with pytest";
    homepage = "https://github.com/pytest-dev/pytest-mock";
    changelog = "https://github.com/pytest-dev/pytest-mock/blob/${finalAttrs.src.tag}/CHANGELOG.rst";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
  };
})
