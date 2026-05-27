{
  lib,
  buildPythonPackage,
  fetchPypi,
  pythonOlder,
  pytestCheckHook,
}:

buildPythonPackage (finalAttrs: {
  pname = "mock";
  version = "5.2.0";
  format = "setuptools";

  disabled = pythonOlder "3.6";

  src = fetchPypi {
    inherit (finalAttrs) pname version;
    hash = "sha256-TkYOgYYptLFz8y0IvzDTr4Ejr7uOBLtXB6H9R5nlA/A=";
  };

  nativeCheckInputs = [ pytestCheckHook ];

  pythonImportsCheck = [ "mock" ];

  passthru.tests.unittests = finalAttrs.finalPackage.overridePythonAttrs { doCheck = true; };

  meta = {
    description = "Rolling backport of unittest.mock for all Pythons";
    homepage = "https://github.com/testing-cabal/mock";
    changelog = "https://github.com/testing-cabal/mock/blob/${finalAttrs.version}/CHANGELOG.rst";
    license = lib.licenses.bsd2;

  };
})
