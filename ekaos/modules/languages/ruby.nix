# Ruby programming language module
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
    defaultLspPackage = pkgs: pkgs.solargraph or null;
    environmentVariables = _: {
      GEM_HOME = "$HOME/.gem";
    };
    sessionPath = _: [ "$HOME/.gem/bin" ];
  };
in

mod { inherit config lib pkgs; }
