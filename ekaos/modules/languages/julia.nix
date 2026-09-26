# Adios port of ekaos/modules/languages/julia.nix.
# Julia programming language module
{ types, pkgs, ... }:

let
  langLib = import ./lib.nix { inherit types; };
in
langLib.mkLanguageModule {
  inherit pkgs;

  name = "julia";
  defaultPackage = pkgs: pkgs.julia;
  environmentVariables = _: {
    JULIA_DEPOT_PATH = "$HOME/.julia";
  };
}
