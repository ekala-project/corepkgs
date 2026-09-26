# Adios port of ekaos/modules/languages/nim.nix.
# Nim programming language module
{ types, pkgs, ... }:

let
  langLib = import ./lib.nix { inherit types; };
in
langLib.mkLanguageModule {
  inherit pkgs;

  name = "nim";
  defaultPackage = pkgs: pkgs.nim;
  environmentVariables = _: {
    NIMBLE_DIR = "$HOME/.nimble";
  };
  sessionPath = _: [ "$HOME/.nimble/bin" ];
}
