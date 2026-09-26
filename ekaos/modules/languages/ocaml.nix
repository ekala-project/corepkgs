# Adios port of ekaos/modules/languages/ocaml.nix.
# OCaml programming language module
{ types, pkgs, ... }:

let
  langLib = import ./lib.nix { inherit types; };
in
langLib.mkLanguageModule {
  inherit pkgs;

  name = "ocaml";
  defaultPackage = pkgs: pkgs.ocaml;
}
