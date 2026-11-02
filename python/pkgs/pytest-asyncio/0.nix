{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  pytest,
  setuptools-scm,
  hypothesis,
  pytestCheckHook,
}:

buildPythonPackage (finalAttrs: {
  pname = "pytest-asyncio";
  version = "0.26.0"; # N.B.: when updating, tests bleak and aioesphomeapi tests
  pyproject = true;

  src = fetchFromGitHub {
    owner = "pytest-dev";
    repo = "pytest-asyncio";
    tag = "v${finalAttrs.version}";
    hash = "sha256-GEhFwwQCXwtqfSiew/sOvJYV3JREqOGD4fQONlRR/Mw=";
  };

  testPaths = [ "tests" ];

  build-system = [ setuptools-scm ];

  buildInputs = [ pytest ];

  nativeTestOnlyCheckInputs = [
    hypothesis
    pytestCheckHook
  ];

  pythonImportsCheck = [ "pytest_asyncio" ];

  meta = {
    description = "Library for testing asyncio code with pytest";
    homepage = "https://github.com/pytest-dev/pytest-asyncio";
    changelog = "https://github.com/pytest-dev/pytest-asyncio/blob/${finalAttrs.src.tag}/docs/reference/changelog.rst";
    license = lib.licenses.asl20;
    platforms = lib.platforms.all;
  };
})
