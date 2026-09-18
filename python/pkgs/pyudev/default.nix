{
  lib,
  buildPythonPackage,
  fetchPypi,
  setuptools,
  six,
  stdenv,
  udev,
}:

buildPythonPackage (finalAttrs: {
  pname = "pyudev";
  version = "0.24.4";
  pyproject = true;

  src = fetchPypi {
    inherit (finalAttrs) pname version;
    hash = "sha256-54i7mDcAsahO/C6IhisKUa8qmV1bhryZl1RlBc97Nrw=";
  };

  postPatch = lib.optionalString stdenv.hostPlatform.isLinux ''
    substituteInPlace src/pyudev/_ctypeslib/utils.py \
      --replace "find_library(name)" "'${lib.getLib udev}/lib/libudev.so'"
  '';

  build-system = [ setuptools ];

  dependencies = [ six ];

  pythonImportsCheck = [ "pyudev" ];

  meta = {
    description = "Pure Python libudev binding";
    homepage = "https://pyudev.readthedocs.org/";
    changelog = "https://github.com/pyudev/pyudev/blob/v${finalAttrs.version}/CHANGES.rst";
    license = lib.licenses.lgpl21Plus;
  };
})
