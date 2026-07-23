{
  lib,
  buildPythonPackage,
  fetchPypi,
  hatchling,
}:

buildPythonPackage rec {
  pname = "soupsieve";
  version = "2.9.1";
  format = "pyproject";

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-wz5mBbvHHdYosAxjLViuYHwiut4kflJVOSj4O7t1tLo=";
  };

  nativeBuildInputs = [ hatchling ];

  # Circular dependency on beautifulsoup4
  doCheck = false;

  # Circular dependency on beautifulsoup4
  # pythonImportsCheck = [ "soupsieve" ];

  meta = {
    description = "CSS4 selector implementation for Beautiful Soup";
    license = lib.licenses.mit;
    homepage = "https://github.com/facelessuser/soupsieve";

  };
}
