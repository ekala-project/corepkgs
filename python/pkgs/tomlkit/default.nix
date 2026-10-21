{
  lib,
  buildPythonPackage,
  fetchPypi,

  # build-system
  poetry-core,

  # tests
  pytestCheckHook,
  pyyaml,
}:

buildPythonPackage (finalAttrs: {
  pname = "tomlkit";
  version = "0.15.2";
  pyproject = true;

  src = fetchPypi {
    inherit (finalAttrs) pname version;
    hash = "sha256-g+MnVbodINk0C9Bp7pfp9iMrojRrY//LpCXeAffjJ6Y=";
  };

  build-system = [ poetry-core ];

  nativeCheckInputs = [
    pyyaml
    pytestCheckHook
  ];

  testPaths = [ "tests" ];

  pythonImportsCheck = [ "tomlkit" ];

  meta = {
    homepage = "https://github.com/sdispater/tomlkit";
    changelog = "https://github.com/sdispater/tomlkit/blob/${finalAttrs.version}/CHANGELOG.md";
    description = "Style-preserving TOML library for Python";
    license = lib.licenses.mit;
  };
})
