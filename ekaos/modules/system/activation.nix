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
          # Link /etc to the system configuration
          if [ -L /etc/static ]; then
            rm /etc/static
          fi
          ln -sfn ${config.system.build.etc}/etc /etc/static

          # For now, just ensure /etc exists
          # In a full implementation, we'd manage /etc overlays here
          if [ ! -d /etc ]; then
            mkdir -p /etc
          fi

          # Copy files from /etc/static to /etc
          if [ -d /etc/static ]; then
            cp -rL /etc/static/* /etc/ 2>/dev/null || true
          fi
        '';
        supportsDryActivation = true;
      };

      # Set up systemd
      systemd = {
        deps = [ "etc" ];
        text = ''
          echo "Setting up systemd units..."
          # Reload systemd if it's running
          if [ -e /run/systemd/system ]; then
            systemctl daemon-reload || true
          fi
        '';
        supportsDryActivation = false;
      };
    };
  };
}
