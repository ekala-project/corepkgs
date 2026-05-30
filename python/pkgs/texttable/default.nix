{
  lib,
  buildPythonPackage,
  fetchPypi,
  pytestCheckHook,
}:

buildPythonPackage rec {
  pname = "texttable";
  version = "1.7.0";
  format = "setuptools";

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-LSBo+1URWAfTrHekymj6SIA+hOuw7iNA+FgQejZSJjg=";
  };

  nativeCheckInputs = [ pytestCheckHook ];

  pythonImportsCheck = [ "texttable" ];

  testPaths = [ "tests.py" ];

  meta = {
    description = "Module to generate a formatted text table, using ASCII characters";
    homepage = "https://github.com/foutaise/texttable";
    license = lib.licenses.mit;
    maintainers = [ ];
  };
}
