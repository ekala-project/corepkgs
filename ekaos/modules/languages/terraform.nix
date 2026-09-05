# Terraform infrastructure-as-code module (uses OpenTofu, the open-source fork)
{
  config,
  lib,
  pkgs,
  ...
}:

let
  langLib = import ./lib.nix { inherit lib; };
  mod = langLib.mkLanguageModule {
    name = "terraform";
    defaultPackage = pkgs: pkgs.opentofu;
  };
in

mod { inherit config lib pkgs; }
