# ekaos system configuration evaluation
# Entry point for building ekaos systems
{ lib, pkgs }:

{
  modules ? [ ],
  baseModules ? import ./modules/module-list.nix,
  ...
}@args:

let
  # Remove our special arguments from args
  extraArgs = builtins.removeAttrs args [
    "modules"
    "baseModules"
  ];

  # Evaluate the module system
  eval = lib.evalModules {
    modules = baseModules ++ modules;
    specialArgs = {
      inherit lib pkgs;
      modulesPath = ./modules;
    }
    // extraArgs;
  };

in

{
  inherit (eval) config options;

  # Expose the system closure for building
  system = eval.config.system.build.toplevel;

  # Expose other useful outputs
  inherit (eval.config.system.build)
    bootStage2
    activationScript
    etc
    ;
}
