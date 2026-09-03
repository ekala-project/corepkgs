# OpenTofu infrastructure-as-code module
{
  config,
  lib,
  pkgs,
  ...
}:

let
  langLib = import ./lib.nix { inherit lib; };
  mod = langLib.mkLanguageModule {
    name = "opentofu";
    defaultPackage = pkgs: pkgs.opentofu;
  };
in

mod { inherit config lib pkgs; }
