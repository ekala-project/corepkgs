# Adios port of ekaos/modules/config/xdg/terminal-exec.nix.
# TODO(adios-cutover) notes below mark semantics changed in translation.
#
# XDG Default Terminal Execution
{
  types,
  lib,
  pkgs,
  ...
}:

let
  # TODO(adios-cutover): smallest local reimplementation of lib.toLower
  # (no nixpkgs lib allowed); ASCII-only.
  toLower =
    s:
    builtins.replaceStrings
      [
        "A"
        "B"
        "C"
        "D"
        "E"
        "F"
        "G"
        "H"
        "I"
        "J"
        "K"
        "L"
        "M"
        "N"
        "O"
        "P"
        "Q"
        "R"
        "S"
        "T"
        "U"
        "V"
        "W"
        "X"
        "Y"
        "Z"
      ]
      [
        "a"
        "b"
        "c"
        "d"
        "e"
        "f"
        "g"
        "h"
        "i"
        "j"
        "k"
        "l"
        "m"
        "n"
        "o"
        "p"
        "q"
        "r"
        "s"
        "t"
        "u"
        "v"
        "w"
        "x"
        "y"
        "z"
      ]
      s;
in

{
  options = {
    terminal-exec = {
      options = {
        enable = {
          type = types.bool;
          default = false;
          description = ''
            Whether to enable xdg-terminal-exec, the proposed
            Default Terminal Execution Specification.
          '';
        };

        package = {
          type = types.nullOr types.derivation;
          default = pkgs.xdg-terminal-exec or null;
          description = "The xdg-terminal-exec package to use.";
        };

        settings = {
          type = types.attrsOf (types.listOf types.string);
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
      description = "XDG default terminal execution settings.";
    };
  };

  assertions = [
    {
      verify =
        { options, ... }: (!options.terminal-exec.enable) || (options.terminal-exec.package != null);
      explain =
        { options, ... }: "package option must be set when enabled (xdg-terminal-exec is not in core-pkgs)";
    }
  ];

  impl =
    { options, ... }:
    if !options.terminal-exec.enable then
      { }
    else
      {
        environment.systemPackages = [ options.terminal-exec.package ];

        environment.etc = lib.merge.attrs.recursively {
          mutators = builtins.map (
            desktop:
            let
              terminals = options.terminal-exec.settings.${desktop};
              filename =
                if desktop == "default" then
                  "xdg/xdg-terminals.list"
                else
                  "xdg/${toLower desktop}-xdg-terminals.list";
            in
            {
              "${filename}".text = builtins.concatStringsSep "\n" terminals + "\n";
            }
          ) (builtins.attrNames options.terminal-exec.settings);
        };
      };
}
