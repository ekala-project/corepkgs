# TeX Live module
{
  config,
  lib,
  pkgs,
  ...
}:

let
  langLib = import ./lib.nix { inherit lib; };
  mod = langLib.mkLanguageModule {
    name = "texlive";
    defaultPackage = pkgs: pkgs.texlive;
  };
in

mod { inherit config lib pkgs; }
