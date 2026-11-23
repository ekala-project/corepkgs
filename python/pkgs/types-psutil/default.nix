{
  lib,
  buildPythonPackage,
  fetchPypi,
}:

buildPythonPackage (finalAttrs: {
  pname = "types-psutil";
  version = "7.2.2.20261122";
  format = "wheel";

  src = fetchPypi {
    pname = "types_psutil";
    inherit (finalAttrs) version;
    format = "wheel";
    dist = "py3";
    python = "py3";
    hash = "sha256-7mDUfN227KzmiutTJrzkf+9wagD3KN9+wn2uMdTthHI=";
  };

  pythonImportsCheck = [ "psutil-stubs" ];

  meta = {
    description = "Typing stubs for psutil";
    homepage = "https://github.com/python/typeshed";
    license = lib.licenses.asl20;
    platforms = lib.platforms.all;
  };
})
