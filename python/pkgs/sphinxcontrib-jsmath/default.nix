{
  lib,
  buildPythonPackage,
  fetchPypi,
  isPy27,
  setuptools,
}:

buildPythonPackage (finalAttrs: {
  pname = "sphinxcontrib-jsmath";
  version = "1.0.1";
  pyproject = true;

  build-system = [ setuptools ];
  disabled = isPy27;

  src = fetchPypi {
    inherit (finalAttrs) pname version;
    hash = "sha256-qZJeSkWHJH7SGRoi319pcGVsuMor1ihDCVePIVPgxLg=";
  };

  pythonNamespaces = [ "sphinxcontrib" ];

  # Check is disabled due to circular dependency of sphinx
  # pythonImportsCheck = [ "sphinxcontrib.jsmath" ];

  meta = {
    description = "Sphinx extension which renders display math in HTML via JavaScript";
    homepage = "https://github.com/sphinx-doc/sphinxcontrib-jsmath";
    license = lib.licenses.bsd0;
    platforms = lib.platforms.all;
  };
})
