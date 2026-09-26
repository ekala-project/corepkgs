# Adios port of ekaos/modules/languages/idris.nix.
# Idris2 programming language module
{ types, pkgs, ... }:

let
  langLib = import ./lib.nix { inherit types; };
in
langLib.mkLanguageModule {
  inherit pkgs;

  name = "idris";
  defaultPackage = pkgs: pkgs.idris2;
}
