# Adios port of ekaos/modules/languages/kotlin.nix.
# Kotlin programming language module
{ types, pkgs, ... }:

let
  langLib = import ./lib.nix { inherit types; };
in
langLib.mkLanguageModule {
  inherit pkgs;

  name = "kotlin";
  defaultPackage = pkgs: pkgs.kotlin;
}
