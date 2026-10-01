# home.users.<name> — per-user home configuration namespace
#
# Declares the top-level home.* option tree, separate from system
# account management (users.users). This module has no system
# dependencies and can be loaded by the standalone home evaluator,
# the full system evaluator, or the dev-shell evaluator.
{ lib, ... }:

let
  inherit (lib)
    mkOption
    mkEnableOption
    types
    literalExpression
    ;

  # Submodule for individual home-managed files
  homeFileOpts =
    { name, ... }:
    {
      options = {
        enable = mkOption {
          type = types.bool;
          default = true;
          description = "Whether this file should be managed.";
        };

        target = mkOption {
          type = types.str;
          default = name;
          description = "Path relative to the user's home directory.";
        };

        source = mkOption {
          type = types.nullOr types.path;
          default = null;
          description = "Source file or directory to link.";
        };

        text = mkOption {
          type = types.nullOr types.lines;
          default = null;
          description = "Text content of the file.";
        };

        executable = mkOption {
          type = types.bool;
          default = false;
          description = "Whether the file should be executable.";
        };
      };
    };

  # Submodule for per-user activation scripts
  homeActivationOpts = {
    options = {
      deps = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = "List of activation scripts this one depends on.";
      };

      text = mkOption {
        type = types.lines;
        description = "Shell script content.";
      };
    };
  };

  # Per-user home configuration submodule
  homeUserOpts =
    { name, ... }:
    {
      options = {
        file = mkOption {
          type = types.attrsOf (types.submodule homeFileOpts);
          default = { };
          description = ''
            Files to manage in the user's home directory.

            Each attribute defines a file relative to $HOME.
            Files are symlinked from the nix store during activation.
          '';
          example = literalExpression ''
            {
              ".bashrc".text = "PS1='$ '";
              ".config/git/config".source = ./dotfiles/gitconfig;
            }
          '';
        };

        stateVersion = mkOption {
          type = types.str;
          default = "24.11";
          description = "Home configuration state version for compatibility tracking.";
        };

        activation = mkOption {
          type = types.attrsOf (types.submodule homeActivationOpts);
          default = { };
          description = ''
            Per-user activation scripts that run during home activation.

            Scripts are topologically sorted by the deps field and
            run as the user (no root privileges).
          '';
          example = literalExpression ''
            {
              setupVim = {
                deps = [];
                text = "mkdir -p $HOME/.vim/undo";
              };
            }
          '';
        };

        packages = mkOption {
          type = types.listOf types.package;
          default = [ ];
          description = "Packages to install in the user's environment.";
          example = literalExpression "[ pkgs.git pkgs.vim pkgs.ripgrep ]";
        };

        sessionVariables = mkOption {
          type = types.attrsOf types.str;
          default = { };
          description = "Environment variables to set in the user's session.";
          example = literalExpression ''
            {
              EDITOR = "vim";
              PAGER = "less";
            }
          '';
        };

        sessionPath = mkOption {
          type = types.listOf types.str;
          default = [ ];
          description = "Directories to prepend to the user's PATH.";
          example = [
            "$HOME/.local/bin"
            "$HOME/go/bin"
          ];
        };

        shellAliases = mkOption {
          type = types.attrsOf types.str;
          default = { };
          description = "Shell aliases for the user.";
          example = literalExpression ''
            {
              ll = "ls -la";
              gs = "git status";
            }
          '';
        };
      };
    };

in

{
  options.home = {
    users = mkOption {
      type = types.attrsOf (types.submodule homeUserOpts);
      default = { };
      description = ''
        Per-user home configuration.

        Each attribute name is a username. The user's home directory
        will be managed declaratively: packages installed, dotfiles
        symlinked, environment variables set, and activation scripts
        run during home activation.

        This namespace is independent of system account management
        (users.users) and can be evaluated standalone without a
        full system configuration.
      '';
      example = literalExpression ''
        {
          alice = {
            packages = [ pkgs.git pkgs.vim ];
            sessionVariables.EDITOR = "vim";
            file.".bashrc".text = "PS1='$ '";
          };
        }
      '';
    };
  };
}
