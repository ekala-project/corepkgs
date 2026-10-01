# Standalone home configuration evaluator
#
# Evaluates home.users.* without loading any system modules
# (no boot, kernel, networking, systemd, /etc management, etc.).
#
# Usage:
#   let
#     eval = import ./eval-home.nix { inherit lib pkgs; };
#     result = eval {
#       modules = [
#         {
#           home.users.alice = {
#             packages = [ pkgs.git pkgs.vim ];
#             sessionVariables.EDITOR = "vim";
#             file.".bashrc".text = "PS1='$ '";
#           };
#         }
#       ];
#     };
#   in result.activationPackage
#
# Works on Linux and Darwin (no systemd/kernel dependencies).
{ lib, pkgs }:

{
  modules ? [ ],
  baseModules ? import ./modules/home-module-list.nix,
  specialArgs ? { },
}:

let
  eval = lib.evalModules {
    modules = baseModules ++ modules;
    specialArgs = {
      inherit lib pkgs;
      modulesPath = ./modules;
    }
    // specialArgs;
  };

in
{
  inherit (eval) config options;

  # The combined activation package for all configured users
  activationPackage = eval.config.home.build.activationPackage;

  # Per-user activation packages
  activationPackages = eval.config.home.build.activationPackages;
}
