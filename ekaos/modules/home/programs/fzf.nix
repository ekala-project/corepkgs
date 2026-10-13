# Per-user fzf configuration
#
# Extends home.users.<name> with fzf options.
# When enabled, installs fzf and optionally sources keybindings
# and fuzzy completion in bash.
#
# Usage:
#   home.users.alice.programs.fzf = {
#     enable = true;
#     keybindings = true;
#     fuzzyCompletion = true;
#   };
{ lib, pkgs, ... }:

let
  inherit (lib)
    mkOption
    mkEnableOption
    mkIf
    types
    concatStringsSep
    optional
    ;

  fzfOpts =
    { config, ... }:
    let
      cfg = config.programs.fzf;
    in
    {
      options.programs.fzf = {
        enable = mkEnableOption "per-user fzf integration";

        package = mkOption {
          type = types.package;
          default = pkgs.fzf;
          description = "fzf package to use.";
        };

        keybindings = mkOption {
          type = types.bool;
          default = true;
          description = "Whether to enable fzf keybindings in bash.";
        };

        fuzzyCompletion = mkOption {
          type = types.bool;
          default = true;
          description = "Whether to enable fzf fuzzy completion in bash.";
        };
      };

      config = mkIf cfg.enable {
        packages = [ cfg.package ];

        programs.bash.initExtra = mkIf (cfg.keybindings || cfg.fuzzyCompletion) (
          lib.mkOrder 950 (
            concatStringsSep "\n" (
              optional cfg.fuzzyCompletion "source ${cfg.package}/share/fzf/completion.bash"
              ++ optional cfg.keybindings "source ${cfg.package}/share/fzf/key-bindings.bash"
            )
          )
        );
      };
    };
in

{
  options.home.users = mkOption {
    type = types.attrsOf (types.submodule fzfOpts);
  };
}
