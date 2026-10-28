{
  lib,
  fetchPypi,
  buildPythonPackage,
  pytestCheckHook,
  setuptools,
}:

buildPythonPackage (finalAttrs: {
  pname = "semantic-version";
  version = "2.10.0";
  pyproject = true;

  build-system = [ setuptools ];

  src = fetchPypi {
    pname = "semantic_version";
    inherit (finalAttrs) version;
    hash = "sha256-vau20zaZjLs3jUuds6S1ah4yNXAdwF6iaQ2amX7VBBw=";
  };

  nativeCheckInputs = [ pytestCheckHook ];

  testPaths = [ "tests" ];

  pythonImportsCheck = [ "semantic_version" ];

  meta = {
    description = "Library implementing the 'SemVer' scheme";
    homepage = "https://github.com/rbarrois/python-semanticversion/";
    license = lib.licenses.bsd2;
    platforms = lib.platforms.all;
  };
})
