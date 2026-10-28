{
  lib,
  buildPythonPackage,
  fetchPypi,
  setuptools,
}:

buildPythonPackage (finalAttrs: {
  pname = "types-setuptools";
  version = "80.9.0.20250822";
  pyproject = true;

  src = fetchPypi {
    pname = "types_setuptools";
    inherit (finalAttrs) version;
    hash = "sha256-Bw6ncWlo7GeoTH93aNmVL/JNKLZbZZR5ekZPGzBm+WU=";
  };

  nativeBuildInputs = [ setuptools ];

  pythonImportsCheck = [ "setuptools-stubs" ];

  meta = {
    description = "Typing stubs for setuptools";
    homepage = "https://github.com/python/typeshed";
    license = lib.licenses.asl20;
    platforms = lib.platforms.all;
  };
})
