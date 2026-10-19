{
  lib,
  buildPythonPackage,
  fetchPypi,
  setuptools,
}:

buildPythonPackage (finalAttrs: {
  pname = "ply";
  version = "3.11";
  pyproject = true;

  build-system = [ setuptools ];

  src = fetchPypi {
    inherit (finalAttrs) pname version;
    hash = "sha256-AMfBqqiDWLnHZbbTAAxu7AukKrylNRsJUyGu9EYIHaM=";
  };

  meta = {
    homepage = "http://www.dabeaz.com/ply/";
    description = "PLY (Python Lex-Yacc), an implementation of lex and yacc parsing tools for Python";
    license = lib.licenses.bsd3;
  };
})
