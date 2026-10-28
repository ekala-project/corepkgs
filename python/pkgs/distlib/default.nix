{
  lib,
  stdenv,
  buildPythonPackage,
  fetchPypi,
  setuptools,
}:

buildPythonPackage (finalAttrs: {
  pname = "distlib";
  version = "0.4.4";
  pyproject = true;

  src = fetchPypi {
    inherit (finalAttrs) pname version;
    hash = "sha256-ykF1tKx/cSI8ww7XJIxF0rOMJDnY7m5JirZ+1jzzUI0=";
  };

  build-system = [ setuptools ];

  postFixup = lib.optionalString (!stdenv.hostPlatform.isWindows) ''
    find $out -name '*.exe' -delete
  '';

  pythonImportsCheck = [
    "distlib"
    "distlib.database"
    "distlib.locators"
    "distlib.index"
    "distlib.markers"
    "distlib.metadata"
    "distlib.util"
    "distlib.resources"
  ];

  meta = {
    description = "Low-level components of distutils2/packaging";
    homepage = "https://distlib.readthedocs.io";
    license = lib.licenses.psfl;
    platforms = lib.platforms.all;
  };
})
