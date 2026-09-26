# Adios port of ekaos/modules/languages/jsonnet.nix.
# Jsonnet data templating language module
{ types, pkgs, ... }:

let
  langLib = import ./lib.nix { inherit types; };
in
langLib.mkLanguageModule {
  inherit pkgs;

  name = "jsonnet";
  defaultPackage = pkgs: pkgs.jsonnet;
}
