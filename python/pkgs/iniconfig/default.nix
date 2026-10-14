{
  lib,
  buildPythonPackage,
  replaceVars,
  fetchPypi,
  setuptools,
}:

buildPythonPackage (finalAttrs: {
  pname = "iniconfig";
  version = "2.3.0";
  pyproject = true;

  src = fetchPypi {
    inherit (finalAttrs) pname version;
    hash = "sha256-x2MVx32waGUNScW1YxR3SngE3xb+5EAsHxnW0V2MRzA=";
  };

  build-system = [ setuptools ];

  patches = [
    # Cannot use setuptools-scm, due to an infinite recursion
    (replaceVars ./version.patch {
      inherit (finalAttrs) version;
    })
  ];

  pythonImportsCheck = [ "iniconfig" ];

  meta = {
    description = "Brain-dead simple parsing of ini files";
    homepage = "https://github.com/pytest-dev/iniconfig";
    license = lib.licenses.mit;

  };
})
