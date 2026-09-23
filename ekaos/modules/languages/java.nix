# Java programming language module
#
# Usage:
#   languages.java.enable = true;
#   languages.java.version = "21";  # optional: select specific version
{
  config,
  lib,
  pkgs,
  ...
}:

let
  langLib = import ./lib.nix { inherit lib; };
  mod = langLib.mkLanguageModule {
    name = "java";
    defaultPackage = pkgs: pkgs.java;
    resolveVersion = langLib.mkMajorVersionResolver "java";
    environmentVariables = cfg: {
      JAVA_HOME = "${cfg.package}";
    };
  };
in

mod { inherit config lib pkgs; }
