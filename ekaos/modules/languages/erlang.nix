# Adios port of ekaos/modules/languages/erlang.nix.
# Erlang programming language module
{ types, pkgs, ... }:

let
  langLib = import ./lib.nix { inherit types; };
in
langLib.mkLanguageModule {
  inherit pkgs;

  name = "erlang";
  defaultPackage = pkgs: pkgs.erlang;
  resolveVersion = langLib.mkMajorVersionResolver "erlang";
}
