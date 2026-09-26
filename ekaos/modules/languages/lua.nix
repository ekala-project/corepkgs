# Adios port of ekaos/modules/languages/lua.nix.
# Lua programming language module
{ types, pkgs, ... }:

let
  langLib = import ./lib.nix { inherit types; };
in
langLib.mkLanguageModule {
  inherit pkgs;

  name = "lua";
  defaultPackage = pkgs: pkgs.lua;
}
