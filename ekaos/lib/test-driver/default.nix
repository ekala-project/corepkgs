# Package the ekaosTest Python driver

{ pkgs, lib, ... }:

pkgs.python3.pkgs.buildPythonPackage {
  pname = "ekaos-test-driver";
  version = "1.0.0";

  src = ./src;

  # No external dependencies for MVP
  # Future: add colorama, ptpython, etc.
  propagatedBuildInputs = [ ];

  # Simple installation - just copy the module
  format = "other";

  installPhase = ''
    mkdir -p $out/${pkgs.python3.sitePackages}
    cp -r test_driver $out/${pkgs.python3.sitePackages}/
  '';

  meta = with lib; {
    description = "Test driver for ekaos systems";
    platforms = platforms.unix;
  };
}
