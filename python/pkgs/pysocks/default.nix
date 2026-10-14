{
  lib,
  buildPythonPackage,
  fetchPypi,
}:

buildPythonPackage (finalAttrs: {
  pname = "pysocks";
  version = "1.7.1";
  format = "setuptools";

  src = fetchPypi {
    pname = "PySocks";
    inherit (finalAttrs) version;
    sha256 = "184sg65mbmih6ljblfsxcmq5js5l7dj3gpn618w9q5dy3rbh921z";
  };

  pythonImportsCheck = [
    "socks"
    "sockshandler"
  ];

  meta = {
    description = "SOCKS module for Python";
    license = lib.licenses.bsd3;

  };
})
