# Adios port of ekaos/modules/languages/java.nix.
# Java programming language module
#
# Usage:
#   languages.java.enable = true;
#   languages.java.version = "21";  # optional: select specific version
{ types, pkgs, ... }:

let
  langLib = import ./lib.nix { inherit types; };
in
langLib.mkLanguageModule {
  inherit pkgs;

  name = "java";
  defaultPackage = pkgs: pkgs.java;
  resolveVersion = langLib.mkMajorVersionResolver "java";
  environmentVariables = cfg: {
    JAVA_HOME = "${cfg.package}";
  };
}
