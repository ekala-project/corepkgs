# Adios port of ekaos/modules/languages/opentofu.nix.
# OpenTofu infrastructure-as-code module
{ types, pkgs, ... }:

let
  langLib = import ./lib.nix { inherit types; };
in
langLib.mkLanguageModule {
  inherit pkgs;

  name = "opentofu";
  defaultPackage = pkgs: pkgs.opentofu;
}
