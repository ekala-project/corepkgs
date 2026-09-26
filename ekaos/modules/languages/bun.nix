# Adios port of ekaos/modules/languages/bun.nix.
# Bun JavaScript runtime module
{ types, pkgs, ... }:

let
  langLib = import ./lib.nix { inherit types; };
in
langLib.mkLanguageModule {
  inherit pkgs;

  name = "bun";
  defaultPackage = pkgs: pkgs.bun;
  environmentVariables = _: {
    BUN_INSTALL = "$HOME/.bun";
  };
  sessionPath = _: [ "$HOME/.bun/bin" ];
}
