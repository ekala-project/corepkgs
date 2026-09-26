# Adios port of ekaos/modules/languages/elixir.nix.
# Elixir programming language module
{ types, pkgs, ... }:

let
  langLib = import ./lib.nix { inherit types; };
in
langLib.mkLanguageModule {
  inherit pkgs;

  name = "elixir";
  defaultPackage = pkgs: pkgs.elixir;
  environmentVariables = _: {
    MIX_HOME = "$HOME/.mix";
    HEX_HOME = "$HOME/.hex";
  };
  sessionPath = _: [ "$HOME/.mix/escripts" ];
}
