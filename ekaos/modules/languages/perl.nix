# Perl programming language module
{
  config,
  lib,
  pkgs,
  ...
}:

let
  langLib = import ./lib.nix { inherit lib; };
  mod = langLib.mkLanguageModule {
    name = "perl";
    defaultPackage = pkgs: pkgs.perl;
  };
in

mod { inherit config lib pkgs; }
