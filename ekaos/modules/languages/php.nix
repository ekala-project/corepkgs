# Adios port of ekaos/modules/languages/php.nix.
# PHP programming language module
{ types, pkgs, ... }:

let
  langLib = import ./lib.nix { inherit types; };
in
langLib.mkLanguageModule {
  inherit pkgs;

  name = "php";
  defaultPackage = pkgs: pkgs.php;
  resolveVersion = langLib.mkCompactVersionResolver "php";
}
