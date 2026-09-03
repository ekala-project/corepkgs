# PHP programming language module
{
  config,
  lib,
  pkgs,
  ...
}:

let
  langLib = import ./lib.nix { inherit lib; };
  mod = langLib.mkLanguageModule {
    name = "php";
    defaultPackage = pkgs: pkgs.php;
    resolveVersion = langLib.mkCompactVersionResolver "php";
  };
in

mod { inherit config lib pkgs; }
