# Adios port of ekaos/modules/languages/terraform.nix.
# Terraform infrastructure-as-code module (uses OpenTofu, the open-source fork)
{ types, pkgs, ... }:

let
  langLib = import ./lib.nix { inherit types; };
in
langLib.mkLanguageModule {
  inherit pkgs;

  name = "terraform";
  defaultPackage = pkgs: pkgs.opentofu;
}
