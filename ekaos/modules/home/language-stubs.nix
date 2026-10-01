# Stub options for standalone home evaluation
#
# Language modules write to environment.packages, environment.variables,
# and users.users — options that exist in the system evaluator but not
# in the standalone home evaluator. This module provides lightweight
# stubs so language modules evaluate without errors.
#
# In home-only context these values are unused (per-user config goes
# through home.users.<name>.languages instead).
{ lib, ... }:

{
  options.environment.packages = lib.mkOption {
    type = lib.types.listOf lib.types.package;
    default = [ ];
    description = "Stub: packages collected by language modules (unused in home context).";
  };

  options.environment.variables = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.oneOf [
        lib.types.str
        lib.types.path
        lib.types.package
      ]
    );
    default = { };
    description = "Stub: environment variables collected by language modules (unused in home context).";
  };

  options.users.users = lib.mkOption {
    type = lib.types.attrsOf (lib.types.submodule { });
    default = { };
    description = "Stub: per-user system options (unused in home context).";
  };
}
