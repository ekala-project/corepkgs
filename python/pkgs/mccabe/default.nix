{
  lib,
  buildPythonPackage,
  fetchPypi,
  pytest,
}:

buildPythonPackage (finalAttrs: {
  pname = "mccabe";
  version = "0.7.0";
  format = "setuptools";

  src = fetchPypi {
    inherit (finalAttrs) pname version;
    hash = "sha256-NI4CQMM7YLvfTlIxku+RnyjLLD19XHeU90AJKQ8jYyU=";
  };

  buildInputs = [ pytest ];

  pythonImportsCheck = [ "mccabe" ];

  meta = {
    description = "McCabe checker, plugin for flake8";
    homepage = "https://github.com/flintwork/mccabe";
    license = lib.licenses.mit;

  };
})
