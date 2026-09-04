# OCaml programming language module
{
  config,
  lib,
  pkgs,
  ...
}:

let
  langLib = import ./lib.nix { inherit lib; };
  mod = langLib.mkLanguageModule {
    name = "ocaml";
    defaultPackage = pkgs: pkgs.ocaml;
  };
in

mod { inherit config lib pkgs; }
