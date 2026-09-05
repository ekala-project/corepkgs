# Clojure programming language module
{
  config,
  lib,
  pkgs,
  ...
}:

let
  langLib = import ./lib.nix { inherit lib; };
  mod = langLib.mkLanguageModule {
    name = "clojure";
    defaultPackage = pkgs: pkgs.clojure;
  };
in

mod { inherit config lib pkgs; }
