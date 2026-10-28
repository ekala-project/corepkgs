# nix-build -A tests.testers.cmake-testLink
{
  lib,
  testers,
  zlib,
}:

lib.recurseIntoAttrs {

  # Basic test: ZLIB should compile+link via cmake
  zlib-links = testers.cmake.testLink {
    package = zlib;
    moduleNames = [ "ZLIB" ];
    targets = [ "ZLIB::ZLIB" ];
  };

}
