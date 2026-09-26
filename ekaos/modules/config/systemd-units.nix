# Adios port of ekaos/modules/config/systemd-units.nix.
# TODO(adios-cutover) notes below mark semantics changed in translation.
#
# Provides the systemd.* and environment.sessionVariables options
# consumed by desktop environment modules. The systemd service
# manager translates these into unit files under /etc/systemd/.
{
  types,
  lib,
  pkgs,
  ...
}:

let
  filterAttrs =
    pred: set:
    builtins.listToAttrs (
      builtins.map (n: {
        name = n;
        value = set.${n};
      }) (builtins.filter (n: pred n set.${n}) (builtins.attrNames set))
    );

  optionalString = cond: s: if cond then s else "";

  concatMapStringsSep =
    sep: f: xs:
    builtins.concatStringsSep sep (builtins.map f xs);

  mapAttrsToList = f: set: builtins.map (n: f n set.${n}) (builtins.attrNames set);

  # Generate a systemd service unit file from the service attrset
  mkServiceUnit =
    name: svc:
    let
      execStart =
        if svc.script != null then
          "${pkgs.writeShellScript name svc.script}"
        else
          svc.serviceConfig.ExecStart or "";
      envLines = mapAttrsToList (k: v: "Environment=\"${k}=${v}\"") svc.environment;
      pathStr = optionalString (svc.path != [ ]) (
        "Environment=\"PATH=${concatMapStringsSep ":" (p: "${p}/bin") svc.path}:$PATH\""
      );
    in
    pkgs.writeText "${name}.service" ''
      [Unit]
      ${optionalString (svc.description != "") "Description=${svc.description}"}
      ${concatMapStringsSep "\n" (d: "After=${d}") svc.after}
      ${concatMapStringsSep "\n" (d: "Before=${d}") svc.before}
      ${concatMapStringsSep "\n" (d: "Wants=${d}") svc.wants}
      ${concatMapStringsSep "\n" (d: "Requires=${d}") svc.requires}
      ${concatMapStringsSep "\n" (d: "BindsTo=${d}") svc.bindsTo}
      ${concatMapStringsSep "\n" (d: "Conflicts=${d}") svc.conflicts}

      [Service]
      ${optionalString (svc.script != null) "ExecStart=${execStart}"}
      ${builtins.concatStringsSep "\n" (
        mapAttrsToList (k: v: "${k}=${toString v}") (
          builtins.removeAttrs svc.serviceConfig [ "ExecStart" ]
          // (
            if (svc.script == null && svc.serviceConfig ? ExecStart) then
              {
                ExecStart = svc.serviceConfig.ExecStart;
              }
            else
              { }
          )
        )
      )}
      ${builtins.concatStringsSep "\n" envLines}
      ${pathStr}

      [Install]
      ${concatMapStringsSep "\n" (t: "WantedBy=${t}") svc.wantedBy}
      ${concatMapStringsSep "\n" (t: "RequiredBy=${t}") svc.requiredBy}
    '';

  # Generate a systemd socket unit file
  mkSocketUnit =
    name: sock:
    pkgs.writeText "${name}.socket" ''
      [Unit]
      ${optionalString (sock.description != "") "Description=${sock.description}"}

      [Socket]
      ${concatMapStringsSep "\n" (s: "ListenStream=${s}") sock.listenStreams}
      ${builtins.concatStringsSep "\n" (mapAttrsToList (k: v: "${k}=${toString v}") sock.socketConfig)}

      [Install]
      ${concatMapStringsSep "\n" (t: "WantedBy=${t}") sock.wantedBy}
    '';

  # Generate a systemd target drop-in for wants/requires
  mkTargetDropIn =
    name: tgt:
    pkgs.writeText "${name}.conf" ''
      [Unit]
      ${optionalString (tgt.description != "") "Description=${tgt.description}"}
      ${concatMapStringsSep "\n" (u: "Wants=${u}") tgt.wants}
      ${concatMapStringsSep "\n" (u: "Requires=${u}") tgt.requires}
      ${concatMapStringsSep "\n" (u: "After=${u}") tgt.after}
    '';

  # Generate a systemd timer unit file
  mkTimerUnit =
    name: tmr:
    pkgs.writeText "${name}.timer" ''
      [Unit]
      ${optionalString (tmr.description != "") "Description=${tmr.description}"}

      [Timer]
      ${builtins.concatStringsSep "\n" (mapAttrsToList (k: v: "${k}=${toString v}") tmr.timerConfig)}

      [Install]
      ${concatMapStringsSep "\n" (t: "WantedBy=${t}") tmr.wantedBy}
    '';
in

{
  options = {
    # Alias for systemd.defaultTarget (used by some ekapkgs modules)
    defaultUnit = {
      # TODO(adios-cutover): legacy default followed config.systemd.defaultTarget,
      # which is declared outside this batch; decoupled to a static default.
      type = types.string;
      default = "multi-user.target";
      description = "Alias for systemd.defaultTarget.";
    };

    # Packages that ship systemd unit files to be installed
    packages = {
      type = types.listOf types.derivation;
      default = [ ];
      description = ''
        Packages whose systemd unit files are installed to /etc/systemd/.
        Unit files are discovered from lib/systemd/system/ and
        lib/systemd/user/ within each package.
      '';
    };

    # System services
    services = {
      # TODO(adios-cutover): submodule validation lost. Legacy validated each
      # service (enable, description, after/before/wants/requires/bindsTo/
      # conflicts/wantedBy/requiredBy, restartIfChanged, environment, path,
      # script, serviceConfig).
      type = types.attrsOf types.attrs;
      default = { };
      description = "Systemd system service definitions.";
    };

    # Timers
    timers = {
      # TODO(adios-cutover): submodule validation lost. Legacy validated each
      # timer (description, wantedBy, timerConfig).
      type = types.attrsOf types.attrs;
      default = { };
      description = "Systemd timer definitions.";
    };

    # Tmpfiles
    tmpfiles = {
      options = {
        packages = {
          type = types.listOf types.derivation;
          default = [ ];
          description = "Packages whose tmpfiles.d configuration should be installed.";
        };

        settings = {
          type = types.attrsOf types.any;
          default = { };
          description = "Tmpfiles settings (name -> rule attrsets).";
        };
      };
      description = "Tmpfiles settings.";
    };

    # User services, sockets, and targets
    user = {
      options = {
        services = {
          # TODO(adios-cutover): submodule validation lost (same service
          # schema as system services above).
          type = types.attrsOf types.attrs;
          default = { };
          description = "Systemd user service definitions.";
        };

        sockets = {
          # TODO(adios-cutover): submodule validation lost. Legacy validated
          # each socket (description, wantedBy, listenStreams, socketConfig).
          type = types.attrsOf types.attrs;
          default = { };
          description = "Systemd user socket definitions.";
        };

        targets = {
          # TODO(adios-cutover): submodule validation lost. Legacy validated
          # each target (description, wants, requires, after).
          type = types.attrsOf types.attrs;
          default = { };
          description = "Systemd user target definitions (drop-ins).";
        };
      };
      description = "Systemd user units.";
    };

    # Session environment variables (set in user sessions via systemd environment.d)
    sessionVariables = {
      type = types.attrsOf (types.either types.string (types.listOf types.string));
      default = { };
      example = {
        EDITOR = "vim";
        GIO_EXTRA_MODULES = [ "\${pkgs.glib-networking}/lib/gio/modules" ];
      };
      description = ''
        Environment variables set in user login sessions.
        Values can be strings or lists of strings (joined with `:` as separator).
      '';
    };
  };

  impl =
    { options, ... }:
    let
      # Filter to enabled services
      enabledSystemServices = filterAttrs (_: svc: svc.enable) options.services;
      enabledUserServices = filterAttrs (_: svc: svc.enable) options.user.services;
    in
    {
      # Sync defaultUnit → defaultTarget
      # TODO(adios-cutover): priority lost (was mkDefault).
      systemd.defaultTarget = options.defaultUnit;

      # Install unit files from packages and generated units
      environment.etc = lib.merge.attrs.recursively {
        mutators = [
          # System units from packages
          (builtins.listToAttrs (
            builtins.concatMap (
              pkg:
              let
                unitDir = "${pkg}/lib/systemd/system";
              in
              if builtins.pathExists unitDir then
                [
                  {
                    name = "systemd/system-packages/${pkg.name}";
                    value = {
                      source = unitDir;
                    };
                  }
                ]
              else
                [ ]
            ) options.packages
          ))

          # User units from packages
          (builtins.listToAttrs (
            builtins.concatMap (
              pkg:
              let
                unitDir = "${pkg}/lib/systemd/user";
              in
              if builtins.pathExists unitDir then
                [
                  {
                    name = "systemd/user-packages/${pkg.name}";
                    value = {
                      source = unitDir;
                    };
                  }
                ]
              else
                [ ]
            ) options.packages
          ))

          # Tmpfiles from packages
          (builtins.listToAttrs (
            builtins.concatMap (
              pkg:
              let
                tmpfilesDir = "${pkg}/lib/tmpfiles.d";
              in
              if builtins.pathExists tmpfilesDir then
                [
                  {
                    name = "tmpfiles.d/${pkg.name}";
                    value = {
                      source = tmpfilesDir;
                    };
                  }
                ]
              else
                [ ]
            ) options.tmpfiles.packages
          ))

          # Generated system service units
          (builtins.listToAttrs (
            mapAttrsToList (name: svc: {
              name = "systemd/system/${name}.service";
              value = {
                source = mkServiceUnit name svc;
              };
            }) enabledSystemServices
          ))

          # Generated system timer units
          (builtins.listToAttrs (
            mapAttrsToList (name: tmr: {
              name = "systemd/system/${name}.timer";
              value = {
                source = mkTimerUnit name tmr;
              };
            }) options.timers
          ))

          # Generated user service units
          (builtins.listToAttrs (
            mapAttrsToList (name: svc: {
              name = "systemd/user/${name}.service";
              value = {
                source = mkServiceUnit name svc;
              };
            }) enabledUserServices
          ))

          # Generated user socket units
          (builtins.listToAttrs (
            mapAttrsToList (name: sock: {
              name = "systemd/user/${name}.socket";
              value = {
                source = mkSocketUnit name sock;
              };
            }) options.user.sockets
          ))

          # Generated user target drop-ins
          (builtins.listToAttrs (
            mapAttrsToList (name: tgt: {
              name = "systemd/user/${name}.target.d/ekaos.conf";
              value = {
                source = mkTargetDropIn name tgt;
              };
            }) options.user.targets
          ))

          # Session variables via environment.d
          (
            if (options.sessionVariables != { }) then
              {
                "environment.d/50-ekaos.conf".text = builtins.concatStringsSep "\n" (
                  mapAttrsToList (
                    name: value:
                    let
                      strValue = if builtins.isList value then builtins.concatStringsSep ":" value else toString value;
                    in
                    "${name}=${strValue}"
                  ) options.sessionVariables
                );
              }
            else
              { }
          )
        ];
      };

      # Activation script to link package unit files
      system.activationScripts.systemd-units = {
        deps = [ "etc" ];
        text = ''
          # Link systemd package units into the system/user directories
          mkdir -p /etc/systemd/system /etc/systemd/user

          for pkg_dir in /etc/systemd/system-packages/*/; do
            [ -d "$pkg_dir" ] || continue
            for unit in "$pkg_dir"/*; do
              [ -f "$unit" ] || continue
              ln -sf "$unit" "/etc/systemd/system/$(basename "$unit")" 2>/dev/null || true
            done
          done

          for pkg_dir in /etc/systemd/user-packages/*/; do
            [ -d "$pkg_dir" ] || continue
            for unit in "$pkg_dir"/*; do
              [ -f "$unit" ] || continue
              ln -sf "$unit" "/etc/systemd/user/$(basename "$unit")" 2>/dev/null || true
            done
          done

          # Link tmpfiles.d from packages
          mkdir -p /etc/tmpfiles.d
          for pkg_dir in /etc/tmpfiles.d/*/; do
            [ -d "$pkg_dir" ] || continue
            for conf in "$pkg_dir"/*; do
              [ -f "$conf" ] || continue
              ln -sf "$conf" "/etc/tmpfiles.d/$(basename "$conf")" 2>/dev/null || true
            done
          done
        '';
      };
    };
}
