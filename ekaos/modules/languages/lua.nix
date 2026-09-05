# Lua programming language module
{
  config,
  lib,
  pkgs,
  ...
}:

let
  langLib = import ./lib.nix { inherit lib; };
  mod = langLib.mkLanguageModule {
    name = "lua";
    defaultPackage = pkgs: pkgs.lua;
    defaultLspPackage = pkgs: pkgs.lua-language-server;
  };
in

mod { inherit config lib pkgs; }
