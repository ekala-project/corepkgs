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
  version = "3.15.1";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "pytest-dev";
    repo = "pytest-mock";
    tag = "v${finalAttrs.version}";
    hash = "sha256-9h5/cssWs4F0LKnFLjWDsEjB2AYczLvnSjiUdsaEcBQ=";
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

  pythonImportsCheck = [ "pytest_mock" ];

  passthru.tests.unittests = finalAttrs.finalPackage.overridePythonAttrs { doCheck = true; };

  meta = {
    description = "Thin wrapper around the mock package for easier use with pytest";
    homepage = "https://github.com/pytest-dev/pytest-mock";
    changelog = "https://github.com/pytest-dev/pytest-mock/blob/${finalAttrs.src.tag}/CHANGELOG.rst";
    license = lib.licenses.mit;

  };
})
