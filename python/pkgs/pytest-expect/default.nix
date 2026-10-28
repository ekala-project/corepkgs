{
  buildPythonPackage,
  lib,
  fetchPypi,
  pytest,
  u-msgpack-python ? null,
  six,
  setuptools,
}:

buildPythonPackage (finalAttrs: {
  pname = "pytest-expect";
  version = "1.1.0";
  pyproject = true;

  build-system = [ setuptools ];

  src = fetchPypi {
    inherit (finalAttrs) pname version;
    hash = "sha256-NrRGJwRFB5gZfQkICaBfThNknZy6ms3FV86VF9of2Ec=";
  };

  buildInputs = [ pytest ];
  propagatedBuildInputs = lib.optional (u-msgpack-python != null) u-msgpack-python ++ [
    six
  ];

  pythonImportsCheck = [ "pytest_expect" ];

  meta = {
    description = "py.test plugin to store test expectations and mark tests based on them";
    homepage = "https://github.com/gsnedders/pytest-expect";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
  };
})
