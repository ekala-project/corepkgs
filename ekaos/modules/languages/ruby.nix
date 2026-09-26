# Adios port of ekaos/modules/languages/ruby.nix.
# Ruby programming language module
#
# Usage:
#   languages.ruby.enable = true;
{ types, pkgs, ... }:

let
  langLib = import ./lib.nix { inherit types; };
in
langLib.mkLanguageModule {
  inherit pkgs;

  name = "ruby";
  defaultPackage = pkgs: pkgs.ruby;
  environmentVariables = _: {
    GEM_HOME = "$HOME/.gem";
  };
  sessionPath = _: [ "$HOME/.gem/bin" ];
}
