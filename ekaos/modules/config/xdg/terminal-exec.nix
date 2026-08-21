# XDG Default Terminal Execution
{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.xdg.terminal-exec;
in

{
  options = {
    xdg.terminal-exec = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Whether to enable xdg-terminal-exec, the proposed
          Default Terminal Execution Specification.
        '';
      };

      package = mkOption {
        type = types.package;
        default = pkgs.xdg-terminal-exec or (throw "xdg-terminal-exec package not available");
        defaultText = literalExpression "pkgs.xdg-terminal-exec";
        description = "The xdg-terminal-exec package to use.";
      };

      settings = mkOption {
        type = types.attrsOf (types.listOf types.str);
        default = { };
        example = {
          default = [ "kitty.desktop" ];
          GNOME = [
            "com.raggesilver.BlackBox.desktop"
            "org.gnome.Terminal.desktop"
          ];
        };
        description = ''
          Terminal preferences per desktop environment.

          Keys are desktop environment names (matched case-insensitively
          against $XDG_CURRENT_DESKTOP) or "default".
          Values are lists of terminal desktop file IDs in priority order.
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ cfg.package ];

    environment.etc = mkMerge (
      mapAttrsToList (
        desktop: terminals:
        let
          filename =
            if desktop == "default" then
              "xdg/xdg-terminals.list"
            else
              "xdg/${lib.toLower desktop}-xdg-terminals.list";
        in
        {
          "${filename}".text = concatStringsSep "\n" terminals + "\n";
        }
      ) cfg.settings
    );
  };
}
