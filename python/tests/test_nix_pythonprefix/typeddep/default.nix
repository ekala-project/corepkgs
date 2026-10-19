{
  lib,
  buildPythonPackage,
  pythonOlder,
  setuptools,
}:

buildPythonPackage {

  pname = "typeddep";
  version = "1.3.3.7";
  pyproject = true;

  build-system = [ setuptools ];

  src = lib.fileset.toSource {
    root = ./.;
    fileset = lib.fileset.unions [
      ./setup.py
      ./typeddep
    ];
  };

  disabled = pythonOlder "3.7";

}
