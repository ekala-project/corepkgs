# Adios port of ekaos/modules/system/activation.nix.
#
# Tree path: system/activation is parent.system.activation.
# Reads the built /etc tree via inputs.etcBuild
# (parent.system.etc, option buildEtc).
# `stringAfter deps text` maps to { deps, text } per activationScriptType
# ({ deps, text, supportsDryActivation }).
# TODO(adios-cutover): activationScripts is types.attrsOf types.attrs;
# per-script submodule validation lost (expected keys: deps list, text
# lines, supportsDryActivation bool).
# TODO(adios-cutover): impl returns both system.build.activationScript
# (this module's read-only output) and the core system.activationScripts
# entries; the tree must merge impl outputs back (NixOS module-merge
# semantics). On key collision the user-provided script wins (legacy
# merged submodule fields instead).
{ types, pkgs, ... }:

let
  # Topologically sort activation scripts by dependencies (Kahn's algorithm)
  sortActivationScripts =
    scripts:
    let
      scriptNames = builtins.attrNames scripts;
      sort =
        remaining: sorted:
        if remaining == [ ] then
          sorted
        else
          let
            ready = builtins.filter (
              name:
              let
                deps = scripts.${name}.deps or [ ];
                unsatisfied = builtins.filter (d: builtins.elem d remaining) deps;
              in
              unsatisfied == [ ]
            ) remaining;
            newRemaining = builtins.filter (name: !(builtins.elem name ready)) remaining;
          in
          if ready == [ ] then
            throw "Circular dependency in activation scripts: ${toString remaining}"
          else
            sort newRemaining (sorted ++ ready);
    in
    sort scriptNames [ ];

  # Build the activation script from a merged script set + the /etc build.
  buildActivationScriptBuilder =
    { scripts, etcBuild }:
    let
      sortedScripts = sortActivationScripts scripts;
      scriptBodies = builtins.map (
        name:
        let
          script = scripts.${name};
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

      ${builtins.concatStringsSep "\n" scriptBodies}

      echo "Activation complete."
    '';

  # Core activation scripts contributed by this module (legacy config
  # section merged these with user-provided scripts).
  buildCoreScripts =
    { inputs }:
    let
      etcBuild = inputs.etcBuild.buildEtc;
    in
    {
      # Set up /etc
      etc = {
        deps = [ ];
        text = ''
          echo "Setting up /etc..."
          # Link /etc to the system configuration
          if [ -L /etc/static ]; then
            rm /etc/static
          fi
          ln -sfn ${etcBuild}/etc /etc/static

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

            # Reload user service managers for all logged-in users
            for uid in $(loginctl list-users --no-legend 2>/dev/null | awk '{print $1}'); do
              systemctl --user -M "$uid@" daemon-reload 2>/dev/null || true
            done
          fi
        '';
        supportsDryActivation = false;
      };
    };
in

{
  options = {
    activationScripts = {
      type = types.attrsOf types.attrs;
      default = { };
      example = {
        myScript = {
          deps = [ "etc" ];
          text = ''
            echo "Setting up my component"
            mkdir -p /var/lib/myservice
          '';
        };
      };
      description = ''
        Activation scripts that configure the system.

        These scripts run during system activation (boot and switch).
        They should be idempotent and handle being run multiple times.

        Scripts are run in dependency order based on the 'deps' field.
      '';
    };

    # Exposed as an option (via defaultFunc) so sibling modules can consume it
    # through adios inputs, which only see OPTIONS, never impl results.
    buildActivationScript = {
      type = types.derivation;
      defaultFunc = { options, inputs }:
        buildActivationScriptBuilder {
          scripts = buildCoreScripts { inherit inputs; } // options.activationScripts;
          etcBuild = inputs.etcBuild.buildEtc;
        };
      description = ''
        The system activation script.
        Read-only output; value comes from the defaultFunc.
      '';
    };
  };

  inputs = {
    etcBuild.from = { parent }: parent.etc;
  };

  impl =
    { options, inputs }:
    let
      core = buildCoreScripts { inherit inputs; };
    in
    {
      system.build.activationScript = buildActivationScriptBuilder {
        scripts = core // options.activationScripts;
        etcBuild = inputs.etcBuild.buildEtc;
      };

      # Core activation scripts contribution (tree merges with user scripts).
      system.activationScripts = core;
    };
}
