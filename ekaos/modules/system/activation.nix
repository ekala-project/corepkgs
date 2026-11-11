# System activation script framework
# Builds and manages activation scripts that configure the system
{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  # Activation script type
  activationScriptType = types.submodule {
    options = {
      deps = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = "List of activation scripts this one depends on.";
      };

      text = mkOption {
        type = types.lines;
        description = "Shell script content for this activation script.";
      };

      supportsDryActivation = mkOption {
        type = types.bool;
        default = false;
        description = "Whether this script supports dry activation (testing mode).";
      };
    };
  };

  # Topologically sort activation scripts by dependencies
  sortActivationScripts =
    scripts:
    let
      # Create dependency graph
      scriptNames = attrNames scripts;

      # Simple topological sort (Kahn's algorithm)
      sort =
        remaining: sorted:
        if remaining == [ ] then
          sorted
        else
          let
            # Find scripts with no unsatisfied dependencies
            ready = filter (
              name:
              let
                deps = scripts.${name}.deps or [ ];
                unsatisfied = filter (d: elem d remaining) deps;
              in
              unsatisfied == [ ]
            ) remaining;

            # Remove ready scripts from remaining
            newRemaining = filter (name: !(elem name ready)) remaining;
          in
          if ready == [ ] then
            throw "Circular dependency in activation scripts: ${toString remaining}"
          else
            sort newRemaining (sorted ++ ready);
    in
    sort scriptNames [ ];

  # Reconciles /etc/systemd/{system,user} against /etc/static
  pruneEtc = pkgs.writeShellScript "ekaos-prune-etc" ''
    export PATH=${
      lib.makeBinPath [
        pkgs.coreutils
        pkgs.findutils
        pkgs.diffutils
      ]
    }
    ${builtins.readFile ./prune-etc.sh}
  '';

  syncUnitDir = pkgs.writeShellScript "ekaos-sync-unit-dir" ''
    export PATH=${
      lib.makeBinPath [
        pkgs.coreutils
        pkgs.findutils
      ]
    }
    ${builtins.readFile ./sync-unit-dir.sh}
  '';

  # Build the activation script
  activationScript =
    let
      sortedScripts = sortActivationScripts config.system.activationScripts;

      scriptBodies = map (
        name:
        let
          script = config.system.activationScripts.${name};
        in
        ''
          # Activation script: ${name}
          ${script.text}
        ''
      ) sortedScripts;

    in
    pkgs.writeScript "activate" ''
      #!${pkgs.runtimeShell}
      set -e

      # Parse arguments
      action="''${1:-switch}"

      echo "Running activation scripts (action: $action)..."

      # Set current system symlink
      mkdir -p /run
      ln -sfn @out@ /run/current-system

      ${concatStringsSep "\n" scriptBodies}

      echo "Activation complete."
    '';

in

{
  options = {
    system.activationScripts = mkOption {
      type = types.attrsOf activationScriptType;
      default = { };
      description = ''
        Activation scripts that configure the system.

        These scripts run during system activation (boot and switch).
        They should be idempotent and handle being run multiple times.

        Scripts are run in dependency order based on the 'deps' field.
      '';
      example = literalExpression ''
        {
          myScript = {
            deps = [ "etc" ];
            text = '''
              echo "Setting up my component"
              mkdir -p /var/lib/myservice
            ''';
          };
        }
      '';
    };

    system.build.activationScript = mkOption {
      type = types.package;
      internal = true;
      description = "The system activation script.";
    };
  };

  config = {
    system.build.activationScript = activationScript;

    # Core activation scripts
    system.activationScripts = {
      # Set up /etc
      etc = {
        deps = [ ];
        text = ''
          echo "Setting up /etc..."
          # Remember the previous generation's tree so files it installed
          # and this one dropped can be pruned below.
          oldEtcStatic=
          if [ -L /etc/static ]; then
            oldEtcStatic=$(readlink -f /etc/static)
            rm /etc/static
          fi
          ln -sfn ${config.system.build.etc}/etc /etc/static

          # For now, just ensure /etc exists
          # In a full implementation, we'd manage /etc overlays here
          if [ ! -d /etc ]; then
            mkdir -p /etc
          fi

          # Copy files from /etc/static to /etc, overwriting any existing files.
          # The systemd unit directories are excluded: they are reconciled
          # below so that administrator state survives activation.
          if [ -d /etc/static ]; then
            for entry in /etc/static/*; do
              if [ "''${entry##*/}" = systemd ] && [ -d "$entry" ]; then
                mkdir -p /etc/systemd
                for sub in "$entry"/*; do
                  case "''${sub##*/}" in
                    system | user) continue ;;
                  esac
                  cp -rfL "$sub" /etc/systemd/
                done
              else
                cp -rfL "$entry" /etc/
              fi
            done
          fi

          # Remove files the previous generation installed and this one no
          # longer provides (administrator changes are kept).
          if [ -n "$oldEtcStatic" ]; then
            ${pruneEtc} "$oldEtcStatic" /etc/static /etc
          fi

          # Staging directories from the old imperative package-unit linking
          rm -rf /etc/systemd/system-packages /etc/systemd/user-packages

          # Reconcile the unit directories: links into /etc/static are
          # managed by the configuration, everything else is left alone.
          ${syncUnitDir} /etc/static/systemd/system /etc/systemd/system
          ${syncUnitDir} /etc/static/systemd/user /etc/systemd/user
        '';
        supportsDryActivation = true;
      };

      # Set up systemd
      systemd = {
        deps = [ "etc" ];
        text = ''
          echo "Setting up systemd units..."

          # Ensure machine-id exists so systemd does not enter first-boot mode
          # (first-boot mode runs systemd-firstboot which prompts interactively)
          if [ ! -s /etc/machine-id ]; then
            ${config.systemd.package}/bin/systemd-machine-id-setup 2>/dev/null \
              || head -c 16 /dev/urandom | od -A n -t x1 | tr -d ' \n' > /etc/machine-id
          fi

          # Reload systemd if it's running
          if [ -e /run/systemd/system ]; then
            systemctl daemon-reload || true

            # Reload user service managers for all logged-in users
            for uid in $(loginctl list-users --no-legend 2>/dev/null | awk '{print $1}'); do
              systemctl --user -M "$uid@" daemon-reload 2>/dev/null || true
            done
          fi
        '';
        supportsDryActivation = false;
      };
    };
  };
}
