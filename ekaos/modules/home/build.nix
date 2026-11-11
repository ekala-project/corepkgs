# Home activation package builder
#
# Reads home.users.<name> config and produces:
#   - home.build.activationPackages.<name>  — per-user activation derivation
#   - home.build.activationPackage          — combined activation for all users
#
# Each per-user package contains:
#   home-files/           symlinked dotfiles
#   home-path/            user's package environment (buildEnv)
#   session-vars.sh       exports for sessionVariables, sessionPath, shellAliases
#   home-files-manifest   JSON list of managed file targets
#   activate              idempotent activation script (runs as user)
{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  # Topologically sort activation scripts (Kahn's algorithm)
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

  # Check if a user has any home configuration worth building
  hasHomeConfig =
    userCfg:
    userCfg.packages != [ ]
    || userCfg.file != { }
    || userCfg.sessionVariables != { }
    || userCfg.sessionPath != [ ]
    || userCfg.shellAliases != { }
    || userCfg.activation != { };

  # Build the home-files derivation for a user
  mkHomeFiles =
    userName: userCfg:
    let
      enabledFiles = filter (f: f.enable) (attrValues userCfg.file);
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
                throw "home.users.${userName}.file.${file.target} has neither source nor text";
          in
          ''
            mkdir -p $out/$(dirname ${escapeShellArg file.target})
            ln -s ${source} $out/${escapeShellArg file.target}
          ''
        ) enabledFiles}

        # Enable user units declaratively, like `systemctl --user enable`:
        # link each unit into <target>.wants/, .requires/ or .upholds/ for
        # its [Install] WantedBy=, RequiredBy= and UpheldBy= targets.
        #
        # Skipped when the unit directory (or a parent) is linked from the
        # store as a whole: it is read-only, so no links can be added.
        unitdir=$out/.config/systemd/user
        if [ -d "$unitdir" ] && [ "$(readlink -f "$unitdir")" = "$unitdir" ]; then
          for unit in "$unitdir"/*.service "$unitdir"/*.socket "$unitdir"/*.timer "$unitdir"/*.path; do
            [ -f "$unit" ] || continue
            name=$(basename "$unit")
            links=$(awk -f ${./unit-install-links.awk} "$unit")

            # A template (foo@.service) is enabled as its DefaultInstance=
            # (foo@<instance>.service); without one, there is nothing to link.
            linkname=$name
            case "$name" in
              *@.*)
                instance=$(echo "$links" | sed -n 's/^instance //p')
                if [ -z "$instance" ]; then
                  echo "warning: $name is a template without DefaultInstance=, not enabling" >&2
                  continue
                fi
                linkname="''${name%@.*}@$instance.''${name##*.}"
                ;;
            esac

            echo "$links" | while read -r kind target; do
              [ "$kind" = instance ] && continue
              [ -n "$target" ] || continue
              mkdir -p "$unitdir/$target.$kind"
              ln -sfn "$(readlink "$unit")" "$unitdir/$target.$kind/$linkname"
            done
          done
        fi
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

  # Build the manifest (JSON list of managed file targets). It lists every
  # link in home-files, including generated ones such as unit .wants links,
  # so the next activation can remove all of them.
  mkManifest =
    userName: homeFiles:
    pkgs.runCommand "home-files-manifest-${userName}"
      {
        preferLocalBuild = true;
        nativeBuildInputs = [ pkgs.jq ];
      }
      ''
        cd ${homeFiles}
        find . -type l | sed 's|^\./||' | LC_ALL=C sort | jq -Rnc '[inputs]' > $out
      '';

  # Build the activation package for a single user
  mkHomeActivationPackage =
    userName: userCfg:
    let
      homeFiles = mkHomeFiles userName userCfg;
      homePath = mkHomePath userName userCfg;
      sessionVars = mkSessionVars userName userCfg;
      manifest = mkManifest userName homeFiles;

      sortedScripts = sortActivationScripts userCfg.activation;
      activationBodies = concatMapStringsSep "\n" (
        name:
        let
          script = userCfg.activation.${name};
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
  usersWithHome = filterAttrs (_: hasHomeConfig) config.home.users;

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
            ln -s ${mkHomeActivationPackage userName userCfg} $out/users/${userName}
          '') usersWithHome
        )}

        cat > $out/activate <<'ACTIVATE'
        #!${pkgs.runtimeShell}
        set -e
        echo "ekaos home: activating all user homes..."
        ${concatStringsSep "\n" (
          mapAttrsToList (userName: userCfg: ''
            echo "  Activating home for ${userName}..."
            ${mkHomeActivationPackage userName userCfg}/activate 2>&1 || \
              echo "  WARNING: home activation failed for ${userName}"
          '') usersWithHome
        )}
        echo "ekaos home: all activations complete."
        ACTIVATE
        chmod +x $out/activate
      '';

in

{
  options.home.build = {
    activationPackages = mkOption {
      type = types.attrsOf types.package;
      internal = true;
      description = "Per-user activation packages, keyed by username.";
    };

    activationPackage = mkOption {
      type = types.package;
      description = ''
        Combined home activation package for all configured users.

        Contains per-user activation packages under users/<name>/ and
        a top-level activate script that runs all of them.
      '';
    };
  };

  config.home.build = {
    activationPackages = mapAttrs mkHomeActivationPackage usersWithHome;
    activationPackage = combinedHome;
  };
}
