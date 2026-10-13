# Per-user direnv configuration
#
# Extends home.users.<name> with direnv options.
# When enabled, installs direnv and adds the shell hook
# to programs.bash.initExtra.
#
# Usage:
#   home.users.alice.programs.direnv = {
#     enable = true;
#   };
{ lib, pkgs, ... }:

let
  inherit (lib)
    mkOption
    mkEnableOption
    mkIf
    types
    ;

  direnvOpts =
    { config, ... }:
    let
      cfg = config.programs.direnv;
    in
    {
      options.programs.direnv = {
        enable = mkEnableOption "per-user direnv integration";

        package = mkOption {
          type = types.package;
          default = pkgs.direnv;
          description = "direnv package to use.";
        };

        enableBashIntegration = mkOption {
          type = types.bool;
          default = true;
          description = "Whether to add the direnv hook to bash.";
        };
      };

      config = mkIf cfg.enable {
        packages = [ cfg.package ];

        programs.bash.initExtra = mkIf cfg.enableBashIntegration (
          lib.mkOrder 900 ''
            eval "$(${cfg.package}/bin/direnv hook bash)"
          ''
        );
      };
    };
in

{
  options.home.users = mkOption {
    type = types.attrsOf (types.submodule direnvOpts);
  };
}
