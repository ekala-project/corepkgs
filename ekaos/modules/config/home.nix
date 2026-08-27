# Per-user home configuration
# Provides declarative management of user dotfiles, packages, environment
# variables, shell aliases, and per-user activation scripts.
#
# Usage in ekaos system configuration:
#   users.users.alice = {
#     packages = [ pkgs.git pkgs.vim ];
#     sessionVariables.EDITOR = "vim";
#     home.file.".bashrc".text = "PS1='$ '";
#   };
#
# The combined home activation package is available at:
#   config.system.build.home
{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
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

  # Topologically sort activation scripts (same algorithm as system activation)
  sortActivationScripts =
    scripts:
    let
      scriptNames = attrNames scripts;
      sort =
        remaining: sorted:
        if remaining == [ ] then
          sorted
        else
          let
            ready = filter (
              name:
              let
                deps = scripts.${name}.deps or [ ];
                unsatisfied = filter (d: elem d remaining) deps;
              in
              unsatisfied == [ ]
            ) remaining;
            newRemaining = filter (name: !(elem name ready)) remaining;
          in
          if ready == [ ] then
            throw "Circular dependency in home activation scripts: ${toString remaining}"
          else
            sort newRemaining (sorted ++ ready);
    in
    sort scriptNames [ ];

  # Check if a user has any home configuration
  hasHomeConfig =
    userCfg:
    userCfg.packages or [ ] != [ ]
    || userCfg.home.file or { } != { }
    || userCfg.sessionVariables or { } != { }
    || userCfg.sessionPath or [ ] != [ ]
    || userCfg.shellAliases or { } != { }
    || userCfg.home.activation or { } != { };

  # Build the home-files derivation for a user
  mkHomeFiles =
    userName: userCfg:
    let
      enabledFiles = filter (f: f.enable) (attrValues userCfg.home.file);
    in
    pkgs.runCommand "home-files-${userName}"
      {
        preferLocalBuild = true;
      }
      ''
        mkdir -p $out

        ${concatMapStringsSep "\n" (
          file:
          let
            source =
              if file.source != null then
                file.source
              else if file.text != null then
                let
                  textFile = pkgs.writeText (baseNameOf file.target) file.text;
                in
                if file.executable then
                  pkgs.runCommand (baseNameOf file.target) { } ''
                    cp ${textFile} $out
                    chmod +x $out
                  ''
                else
                  textFile
              else
                throw "home.file.${file.target} has neither source nor text";
          in
          ''
            mkdir -p $out/$(dirname ${escapeShellArg file.target})
            ln -s ${source} $out/${escapeShellArg file.target}
          ''
        ) enabledFiles}
      '';

  # Build the per-user package environment
  mkHomePath =
    userName: userCfg:
    pkgs.buildEnv {
      name = "home-path-${userName}";
      paths = userCfg.packages;
      pathsToLink = [
        "/bin"
        "/sbin"
        "/lib"
        "/share"
      ];
      ignoreCollisions = true;
    };

  # Generate session-vars.sh for a user
  mkSessionVars =
    userName: userCfg:
    let
      pathEntries =
        (optional (userCfg.packages != [ ]) "$HOME/.ekaos-profile/bin") ++ userCfg.sessionPath;

      pathPrefix =
        if pathEntries != [ ] then ''export PATH="${concatStringsSep ":" pathEntries}:$PATH"'' else "";

      envVars = concatStringsSep "\n" (
        mapAttrsToList (
          name: value: "export ${name}=${escapeShellArg (toString value)}"
        ) userCfg.sessionVariables
      );

      aliases = concatStringsSep "\n" (
        mapAttrsToList (name: value: "alias ${name}=${escapeShellArg value}") userCfg.shellAliases
      );
    in
    pkgs.writeText "session-vars-${userName}.sh" ''
      # Generated by ekaos home configuration. Do not edit.
      ${pathPrefix}
      ${envVars}
      ${aliases}
    '';

  # Build the manifest (JSON list of managed file targets)
  mkManifest =
    userName: userCfg:
    let
      enabledFiles = filter (f: f.enable) (attrValues userCfg.home.file);
      targets = map (f: f.target) enabledFiles;
    in
    pkgs.writeText "home-files-manifest-${userName}" (builtins.toJSON targets);

  # Build the activation package for a single user
  mkHomeActivationPackage =
    userName: userCfg:
    let
      homeFiles = mkHomeFiles userName userCfg;
      homePath = mkHomePath userName userCfg;
      sessionVars = mkSessionVars userName userCfg;
      manifest = mkManifest userName userCfg;

      sortedScripts = sortActivationScripts userCfg.home.activation;
      activationBodies = concatMapStringsSep "\n" (
        name:
        let
          script = userCfg.home.activation.${name};
        in
        ''
          # Home activation: ${name}
          ${script.text}
        ''
      ) sortedScripts;
    in
    pkgs.runCommand "home-${userName}"
      {
        preferLocalBuild = true;
        allowSubstitutes = false;
      }
      ''
        mkdir -p $out

        ln -s ${homeFiles} $out/home-files
        ln -s ${homePath} $out/home-path
        cp ${sessionVars} $out/session-vars.sh
        cp ${manifest} $out/home-files-manifest

        cat > $out/activate <<'ACTIVATE'
        #!${pkgs.runtimeShell}
        set -e

        EKAOS_STATE_DIR="$HOME/.config/ekaos"
        EKAOS_GEN_DIR="$EKAOS_STATE_DIR/generations"
        MANIFEST_FILE="$EKAOS_STATE_DIR/home-files-manifest"
        THIS="$(cd "$(dirname "$0")" && pwd)"

        echo "ekaos home: activating for $(whoami)..."

        # Create state directories
        mkdir -p "$EKAOS_STATE_DIR"
        mkdir -p "$EKAOS_GEN_DIR"

        # Update profile symlink
        if [ -d "$THIS/home-path" ] || [ -L "$THIS/home-path" ]; then
          ln -sfn "$(readlink -f "$THIS/home-path")" "$HOME/.ekaos-profile"
          echo "  Updated ~/.ekaos-profile"
        fi

        # Remove stale symlinks from previous manifest
        if [ -f "$MANIFEST_FILE" ]; then
          for old_target in $(${pkgs.jq}/bin/jq -r '.[]' "$MANIFEST_FILE" 2>/dev/null); do
            target_path="$HOME/$old_target"
            if [ -L "$target_path" ]; then
              rm -f "$target_path"
            fi
          done
        fi

        # Create new symlinks from home-files into HOME
        if [ -d "$THIS/home-files" ]; then
          cd "$THIS/home-files"
          find . -type l | while IFS= read -r link; do
            rel="''${link#./}"
            mkdir -p "$HOME/$(dirname "$rel")"

            dest="$HOME/$rel"
            if [ -e "$dest" ] && [ ! -L "$dest" ]; then
              echo "  WARNING: $rel exists and is not a symlink, backing up"
              mv "$dest" "$dest.ekaos-backup"
            fi

            ln -sfn "$(readlink -f "$link")" "$dest"
          done
          echo "  Linked home files"
        fi

        # Write new manifest
        cp "$THIS/home-files-manifest" "$MANIFEST_FILE"

        # Install session-vars.sh
        cp "$THIS/session-vars.sh" "$EKAOS_STATE_DIR/session-vars.sh"
        echo "  Installed session-vars.sh"

        # Run user activation scripts
        ${activationBodies}

        # Record generation
        gen_num=1
        latest=$(ls -1 "$EKAOS_GEN_DIR" 2>/dev/null | sort -n | tail -1)
        if [ -n "$latest" ]; then
          gen_num=$((latest + 1))
        fi
        ln -sfn "$THIS" "$EKAOS_GEN_DIR/$gen_num"
        ln -sfn "$THIS" "$EKAOS_STATE_DIR/current-home"
        echo "  Generation $gen_num activated"

        echo "ekaos home: activation complete."
        ACTIVATE
        chmod +x $out/activate

        substituteInPlace $out/activate \
          --replace '#!${pkgs.runtimeShell}' '#!${pkgs.runtimeShell}'
      '';

  # All users that have home configuration
  usersWithHome = filterAttrs (_: userCfg: hasHomeConfig userCfg) config.users.users;

  # Combined home derivation containing all user activation packages
  combinedHome =
    pkgs.runCommand "ekaos-home"
      {
        preferLocalBuild = true;
        allowSubstitutes = false;
      }
      ''
        mkdir -p $out/users

        ${concatStringsSep "\n" (
          mapAttrsToList (userName: userCfg: ''
            ln -s ${userCfg.home.activationPackage} $out/users/${userName}
          '') usersWithHome
        )}

        # Write a top-level activate script that activates all users
        cat > $out/activate <<'ACTIVATE'
        #!${pkgs.runtimeShell}
        set -e
        echo "ekaos home: activating all user homes..."
        ${concatStringsSep "\n" (
          mapAttrsToList (userName: userCfg: ''
            echo "  Activating home for ${userName}..."
            su - ${userName} -c "${userCfg.home.activationPackage}/activate" 2>&1 || \
              echo "  WARNING: home activation failed for ${userName}"
          '') usersWithHome
        )}
        echo "ekaos home: all activations complete."
        ACTIVATE
        chmod +x $out/activate
      '';

in

{
  options.users.users = mkOption {
    type = types.attrsOf (
      types.submodule (
        { name, config, ... }:
        {
          options = {
            home.file = mkOption {
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

            home.stateVersion = mkOption {
              type = types.str;
              default = "24.11";
              description = "Home configuration state version for compatibility tracking.";
            };

            home.activation = mkOption {
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

            home.activationPackage = mkOption {
              type = types.package;
              internal = true;
              description = "The built home activation package for this user.";
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

          config = mkIf (hasHomeConfig config) {
            home.activationPackage = mkHomeActivationPackage name config;
          };
        }
      )
    );
  };

  options.system.build.home = mkOption {
    type = types.package;
    description = ''
      Combined home activation package for all configured users.

      Contains per-user activation packages under users/<name>/ and
      a top-level activate script that runs all of them.

      Build with: nix-build -A config.system.build.home
    '';
  };

  config = {
    system.build.home = combinedHome;

    # System activation script that activates home configs during boot/switch
    system.activationScripts.home = {
      deps = [ "users" ];
      text =
        if usersWithHome != { } then
          ''
            echo "Activating per-user home configurations..."
            ${concatStringsSep "\n" (
              mapAttrsToList (userName: userCfg: ''
                echo "  Activating home for ${userName}..."
                su - ${userName} -c "${userCfg.home.activationPackage}/activate" 2>&1 || \
                  echo "  WARNING: home activation failed for ${userName}"
              '') usersWithHome
            )}
          ''
        else
          ''
            # No users with home configuration
          '';
    };
  };
}
