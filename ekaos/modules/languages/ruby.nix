# Ruby programming language module
#
# Usage:
#   languages.ruby.enable = true;
{
  config,
  lib,
  pkgs,
  ...
}:

let
  langLib = import ./lib.nix { inherit lib; };
  mod = langLib.mkLanguageModule {
    name = "ruby";
    defaultPackage = pkgs: pkgs.ruby;
    environmentVariables = _: {
      GEM_HOME = "$HOME/.gem";
    };
    sessionPath = _: [ "$HOME/.gem/bin" ];
  };
in

mod { inherit config lib pkgs; }
