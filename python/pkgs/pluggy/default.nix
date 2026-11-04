{
  buildPythonPackage,
  lib,
  fetchFromGitHub,
  setuptools-scm,
  pythonOlder,
  pytestCheckHook,
}:

buildPythonPackage (finalAttrs: {
  pname = "pluggy";
  version = "1.7.0";

  disabled = pythonOlder "3.8";

  pyproject = true;

  src = fetchFromGitHub {
    owner = "pytest-dev";
    repo = "pluggy";
    tag = finalAttrs.version;
    hash = "sha256-wQr2dFG8gh58v9CbmNhLX3Znuj+JeBAm3SHXJXMztXA=";
  };

  build-system = [ setuptools-scm ];

  nativeTestOnlyCheckInputs = [ pytestCheckHook ];

  pythonImportsCheck = [ "pluggy" ];

  meta = {
    changelog = "https://github.com/pytest-dev/pluggy/blob/${finalAttrs.src.rev}/CHANGELOG.rst";
    description = "Plugin and hook calling mechanisms for Python";
    homepage = "https://github.com/pytest-dev/pluggy";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
  };
})
