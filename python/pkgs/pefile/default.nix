{
  lib,
  buildPythonPackage,
  fetchPypi,
  setuptools,
  pytestCheckHook,
}:

buildPythonPackage (finalAttrs: {
  pname = "pefile";
  version = "2024.8.26";
  format = "pyproject";

  src = fetchPypi {
    inherit (finalAttrs) pname version;
    hash = "sha256-QGK8kbrpDOENJy6eSMMMUFHR+MXyxadY5SJBFj+bX0g=";
  };

  nativeBuildInputs = [ setuptools ];

  nativeCheckInputs = [ pytestCheckHook ];

  pythonImportsCheck = [ "pefile" ];

  meta = {
    description = "Multi-platform Python module to parse and work with Portable Executable files";
    homepage = "https://github.com/erocarrera/pefile";
    license = lib.licenses.mit;
  };
})
