{
  lib,
  buildPythonPackage,
  replaceVars,
  fetchPypi,
  setuptools,
}:

buildPythonPackage (finalAttrs: {
  pname = "iniconfig";
  version = "2.3.1";
  pyproject = true;

  src = fetchPypi {
    inherit (finalAttrs) pname version;
    hash = "sha256-Z/S5xQ2g3t9SrzSed0moCpBXpQMRmXkbkGw7s66HiWA=";
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
