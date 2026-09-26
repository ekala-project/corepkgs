# Adios port of ekaos/modules/languages/dotnet.nix.
# .NET SDK module
{ types, pkgs, ... }:

let
  langLib = import ./lib.nix { inherit types; };
in
langLib.mkLanguageModule {
  inherit pkgs;

  name = "dotnet";
  defaultPackage = pkgs: pkgs.dotnet-sdk;
  environmentVariables = _: {
    DOTNET_ROOT = "$HOME/.dotnet";
  };
  sessionPath = _: [ "$HOME/.dotnet/tools" ];
}
