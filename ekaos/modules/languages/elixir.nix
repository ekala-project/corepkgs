# Elixir programming language module
{
  config,
  lib,
  pkgs,
  ...
}:

let
  langLib = import ./lib.nix { inherit lib; };
  mod = langLib.mkLanguageModule {
    name = "elixir";
    defaultPackage = pkgs: pkgs.elixir;
    defaultLspPackage = pkgs: pkgs.elixir-ls or null;
    environmentVariables = _: {
      MIX_HOME = "$HOME/.mix";
      HEX_HOME = "$HOME/.hex";
    };
    sessionPath = _: [ "$HOME/.mix/escripts" ];
  };
in

mod { inherit config lib pkgs; }
