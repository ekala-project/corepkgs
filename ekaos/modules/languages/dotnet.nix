# .NET SDK module
{
  config,
  lib,
  pkgs,
  ...
}:

let
  langLib = import ./lib.nix { inherit lib; };
  mod = langLib.mkLanguageModule {
    name = "dotnet";
    defaultPackage = pkgs: pkgs.dotnet-sdk;
    environmentVariables = _: {
      DOTNET_ROOT = "$HOME/.dotnet";
    };
    sessionPath = _: [ "$HOME/.dotnet/tools" ];
  };
in

mod { inherit config lib pkgs; }
