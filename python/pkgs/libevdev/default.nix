{
  lib,
  buildPythonPackage,
  fetchPypi,
  replaceVars,
  pkgs,
  hatchling,
}:

buildPythonPackage rec {
  pname = "libevdev";
  version = "0.13.1";
  pyproject = true;

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-3DNpzRQBdnueyxEXzWtz+rqQOOO9nhaVpxCp6dlBXo0=";
  };

  patches = [
    (replaceVars ./fix-paths.patch {
      libevdev = lib.getLib pkgs.libevdev;
    })
  ];

  build-system = [ hatchling ];

  pythonImportsCheck = [ "libevdev" ];

  meta = {
    description = "Python wrapper around the libevdev C library";
    homepage = "https://gitlab.freedesktop.org/libevdev/python-libevdev";
    license = lib.licenses.mit;
  };
}
