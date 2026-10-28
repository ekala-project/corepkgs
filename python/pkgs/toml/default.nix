{
  lib,
  buildPythonPackage,
  fetchPypi,
  setuptools,
}:

buildPythonPackage (finalAttrs: {
  pname = "toml";
  version = "0.10.2";
  pyproject = true;

  build-system = [ setuptools ];

  src = fetchPypi {
    inherit (finalAttrs) pname version;
    hash = "sha256-s72h0QjV3Zn0og0k2cNI6RxNt6sbdJIAve0vg5zL5o8=";
  };

  pythonImportsCheck = [ "toml" ];

  meta = {
    description = "Python library for parsing and creating TOML";
    homepage = "https://github.com/uiri/toml";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
  };
})
