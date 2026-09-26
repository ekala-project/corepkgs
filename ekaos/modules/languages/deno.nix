# Adios port of ekaos/modules/languages/deno.nix.
# Deno JavaScript/TypeScript runtime module
{ types, pkgs, ... }:

let
  langLib = import ./lib.nix { inherit types; };
in
langLib.mkLanguageModule {
  inherit pkgs;

  name = "deno";
  defaultPackage = pkgs: pkgs.deno;
  environmentVariables = _: {
    DENO_DIR = "$HOME/.cache/deno";
  };
}
