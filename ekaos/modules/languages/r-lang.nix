# R programming language module
{
  config,
  lib,
  pkgs,
  ...
}:

let
  langLib = import ./lib.nix { inherit lib; };
  mod = langLib.mkLanguageModule {
    name = "r-lang";
    defaultPackage = pkgs: pkgs.r-lang;
    defaultLspPackage = pkgs: pkgs.r-languageserver or null;
    environmentVariables = _: {
      R_LIBS_USER = "$HOME/.R/library";
    };
  };
in

mod { inherit config lib pkgs; }
