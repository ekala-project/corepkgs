# Per-user htop configuration
#
# Extends home.users.<name> with htop options.
# When enabled, installs htop and generates ~/.config/htop/htoprc
# from the settings attrset.
#
# Usage:
#   home.users.alice.programs.htop = {
#     enable = true;
#     settings = {
#       tree_view = 1;
#       show_program_path = 0;
#     };
#   };
{ lib, pkgs, ... }:

let
  inherit (lib)
    mkOption
    mkEnableOption
    mkIf
    types
    concatStringsSep
    mapAttrsToList
    ;

  # Format a settings value for htoprc
  htopValue =
    v:
    if builtins.isBool v then
      (if v then "1" else "0")
    else if builtins.isList v then
      concatStringsSep " " (map htopValue v)
    else
      toString v;

  htopOpts =
    { config, ... }:
    let
      cfg = config.programs.htop;

      htoprcContent =
        concatStringsSep "\n" (mapAttrsToList (key: value: "${key}=${htopValue value}") cfg.settings)
        + "\n";
    in
    {
      options.programs.htop = {
        enable = mkEnableOption "per-user htop configuration";

        package = mkOption {
          type = types.package;
          default = pkgs.htop;
          description = "htop package to use.";
        };

        settings = mkOption {
          type = types.attrsOf types.anything;
          default = { };
          example = {
            tree_view = 1;
            show_program_path = 0;
            left_meters = [
              "LeftCPUs2"
              "Memory"
              "Swap"
            ];
            right_meters = [
              "RightCPUs2"
              "Tasks"
              "LoadAverage"
              "Uptime"
            ];
          };
          description = ''
            htop settings written to ~/.config/htop/htoprc.
            See htop(1) for available options.
          '';
        };
      };

      config = mkIf cfg.enable {
        packages = [ cfg.package ];

        file.".config/htop/htoprc" = mkIf (cfg.settings != { }) {
          text = htoprcContent;
        };
      };
    };
in

{
  options.home.users = mkOption {
    type = types.attrsOf (types.submodule htopOpts);
  };
}
