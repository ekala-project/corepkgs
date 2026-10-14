{
  lib,
  buildPythonPackage,
  fetchPypi,
  pythonOlder,
  flit-core,
}:

buildPythonPackage (finalAttrs: {
  pname = "sphinxcontrib-qthelp";
  version = "2.0.0";
  pyproject = true;

  disabled = pythonOlder "3.9";

  src = fetchPypi {
    pname = "sphinxcontrib_qthelp";
    inherit (finalAttrs) version;
    hash = "sha256-T+fQrI/BcQRb5iOro+Ko9hP4aCcx+RU7suQOzha5u6s=";
  };

  nativeBuildInputs = [ flit-core ];

  # Check is disabled due to circular dependency of sphinx
  dontCheckRuntimeDeps = true;

  pythonNamespaces = [ "sphinxcontrib" ];

  # Check is disabled due to circular dependency of sphinx
  # pythonImportsCheck = [ "sphinxcontrib.qthelp" ];

  meta = {
    description = "Sphinx extension which outputs QtHelp document";
    homepage = "https://github.com/sphinx-doc/sphinxcontrib-qthelp";
    license = lib.licenses.bsd2;
  };
})
