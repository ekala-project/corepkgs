# Home-system bridge
#
# Loaded only in the full system evaluator. Responsibilities:
#   1. Adds backward-compatible home options to users.users.<name>
#      (packages, sessionVariables, sessionPath, shellAliases, home.file, etc.)
#   2. Forwards users.users.<name> home config → home.users.<name>
#   3. Wires home.users into system activation (runs per-user activate via su)
#   4. Exposes system.build.home as an alias for home.build.activationPackage
{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  # Submodule types for users.users backward compat
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

  usersWithHome = filterAttrs (_: hasHomeConfig) config.home.users;

  hasHomeConfig =
    userCfg:
    userCfg.packages != [ ]
    || userCfg.file != { }
    || userCfg.sessionVariables != { }
    || userCfg.sessionPath != [ ]
    || userCfg.shellAliases != { }
    || userCfg.activation != { };

  # Check if a users.users entry has legacy home config
  hasLegacyHomeConfig =
    userCfg:
    (userCfg.packages or [ ]) != [ ]
    || (userCfg.home.file or { }) != { }
    || (userCfg.sessionVariables or { }) != { }
    || (userCfg.sessionPath or [ ]) != [ ]
    || (userCfg.shellAliases or { }) != { }
    || (userCfg.home.activation or { }) != { };

in

{
  # Backward-compatible options on users.users.<name>
  options.users.users = mkOption {
    type = types.attrsOf (
      types.submodule {
        options = {
          home.file = mkOption {
            type = types.attrsOf (types.submodule homeFileOpts);
            default = { };
            description = "Files to manage in the user's home directory. Prefer home.users.<name>.file.";
          };

          home.stateVersion = mkOption {
            type = types.str;
            default = "24.11";
            description = "Home configuration state version.";
          };

          home.activation = mkOption {
            type = types.attrsOf (types.submodule homeActivationOpts);
            default = { };
            description = "Per-user activation scripts. Prefer home.users.<name>.activation.";
          };

          packages = mkOption {
            type = types.listOf types.package;
            default = [ ];
            description = "Packages for the user's environment. Prefer home.users.<name>.packages.";
          };

          sessionVariables = mkOption {
            type = types.attrsOf types.str;
            default = { };
            description = "Session environment variables. Prefer home.users.<name>.sessionVariables.";
          };

          sessionPath = mkOption {
            type = types.listOf types.str;
            default = [ ];
            description = "Directories to prepend to PATH. Prefer home.users.<name>.sessionPath.";
          };

          shellAliases = mkOption {
            type = types.attrsOf types.str;
            default = { };
            description = "Shell aliases. Prefer home.users.<name>.shellAliases.";
          };
        };
      }
    );
  };

  # system.build.home alias
  options.system.build.home = mkOption {
    type = types.package;
    description = ''
      Combined home activation package for all configured users.
      Alias for config.home.build.activationPackage.
    '';
  };

  config = {
    system.build.home = config.home.build.activationPackage;

    # System activation script that runs home activation during boot/switch
    system.activationScripts.home = {
      deps = [ "users" ];
      text =
        if usersWithHome != { } then
          ''
            echo "Activating per-user home configurations..."
            ${concatStringsSep "\n" (
              mapAttrsToList (userName: _: ''
                echo "  Activating home for ${userName}..."
                su - ${userName} -c "${config.home.build.activationPackages.${userName}}/activate" 2>&1 || \
                  echo "  WARNING: home activation failed for ${userName}"
              '') usersWithHome
            )}
          ''
        else
          ''
            # No users with home configuration
          '';
    };

    # Forward legacy users.users.<name> home options to home.users.<name>
    home.users = mkMerge (
      mapAttrsToList (
        userName: userCfg:
        mkIf (hasLegacyHomeConfig userCfg) {
          ${userName} = {
            packages = userCfg.packages;
            file = userCfg.home.file;
            sessionVariables = userCfg.sessionVariables;
            sessionPath = userCfg.sessionPath;
            shellAliases = userCfg.shellAliases;
            activation = userCfg.home.activation;
            stateVersion = userCfg.home.stateVersion;
          };
        }
      ) config.users.users
    );
  };
}
