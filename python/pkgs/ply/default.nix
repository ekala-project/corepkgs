{
  lib,
  buildPythonPackage,
  fetchPypi,
}:

buildPythonPackage rec {
  pname = "ply";
  version = "3.11";
  format = "setuptools";

  src = fetchPypi {
    inherit pname version;
    sha256 = "00c7c1aaa88358b9c765b6d3000c6eec0ba42abca5351b095321aef446081da3";
  };

  doCheck = false;

  meta = {
    homepage = "http://www.dabeaz.com/ply/";
    description = "PLY (Python Lex-Yacc), an implementation of lex and yacc parsing tools for Python";
    license = lib.licenses.bsd3;
    maintainers = [ ];
  };
}
