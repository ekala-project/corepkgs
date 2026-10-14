{
  lib,
  buildPythonPackage,
  fetchPypi,
}:

buildPythonPackage (finalAttrs: {
  pname = "toml";
  version = "0.10.2";
  format = "setuptools";

  src = fetchPypi {
    inherit (finalAttrs) pname version;
    sha256 = "b3bda1d108d5dd99f4a20d24d9c348e91c4db7ab1b749200bded2f839ccbe68f";
  };

  pythonImportsCheck = [ "toml" ];

  meta = {
    description = "Python library for parsing and creating TOML";
    homepage = "https://github.com/uiri/toml";
    license = lib.licenses.mit;
  };
})
