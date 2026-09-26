# Adios port of ekaos/modules/languages/clojure.nix.
# Clojure programming language module
{ types, pkgs, ... }:

let
  langLib = import ./lib.nix { inherit types; };
in
langLib.mkLanguageModule {
  inherit pkgs;

  name = "clojure";
  defaultPackage = pkgs: pkgs.clojure;
}
