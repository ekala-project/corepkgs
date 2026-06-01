{
  lib,
  buildPythonPackage,
  pystemmer,
  fetchPypi,
}:

buildPythonPackage rec {
  pname = "snowballstemmer";
  version = "3.1.0";
  format = "setuptools";

  src = fetchPypi {
    inherit pname version;
    sha256 = "sha256-/Z40UmsjNAzSP/6myfl2CXTswsKsnh2BQBRDzNsqgB8=";
  };

  # No tests included
  doCheck = false;

  propagatedBuildInputs = [ pystemmer ];

  pythonImportsCheck = [ "snowballstemmer" ];

  meta = {
    description = "16 stemmer algorithms (15 + Poerter English stemmer) generated from Snowball algorithms";
    homepage = "http://sigal.saimon.org/en/latest/index.html";
    license = lib.licenses.bsd3;
    platforms = lib.platforms.unix;
  };
}
