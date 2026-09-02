# Java programming language module
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
    defaultLspPackage = pkgs: pkgs.jdt-language-server or null;
    environmentVariables = cfg: {
      JAVA_HOME = "${cfg.package}";
    };
  };
in

mod { inherit config lib pkgs; }
