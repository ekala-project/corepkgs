# Erlang programming language module
{
  config,
  lib,
  pkgs,
  ...
}:

let
  langLib = import ./lib.nix { inherit lib; };
  mod = langLib.mkLanguageModule {
    name = "erlang";
    defaultPackage = pkgs: pkgs.erlang;
    resolveVersion = langLib.mkMajorVersionResolver "erlang";
  };
in

mod { inherit config lib pkgs; }
