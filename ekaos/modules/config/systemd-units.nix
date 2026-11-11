# Systemd unit and session variable options
#
# Provides the systemd.* and environment.sessionVariables options
# consumed by desktop environment modules. The systemd service
# manager translates these into unit files under /etc/systemd/.
{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.systemd;

  switchKeys = import ../../lib/systemd-switch-keys.nix { inherit lib pkgs; };

  # Options read by the switch engine (see lib/systemd-switch-keys.nix).
  stopOnRemovalOption = mkOption {
    type = types.bool;
    default = true;
    description = "Whether to stop the unit when it is removed from the configuration on switch.";
  };

  onlyManualStartOption = mkOption {
    type = types.bool;
    default = false;
    description = "Whether the switch engine must never start or restart this unit itself.";
  };

  triggersOption =
    what:
    mkOption {
      type = types.listOf types.unspecified;
      default = [ ];
      description = ''
        Values that ${what} the unit on switch when they change, even if the
        unit file itself did not.
      '';
    };

  # Type for systemd unit configuration (serviceConfig, socketConfig, etc.)
  unitConfigType = types.attrsOf (
    types.oneOf [
      types.str
      types.int
      types.bool
      types.path
      types.package
    ]
  );

  # Type for a systemd service unit
  serviceOptions = {
    options = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Whether to enable this service.";
      };

      description = mkOption {
        type = types.str;
        default = "";
        description = "Service description.";
      };

      after = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = "Units that must start before this service.";
      };

      before = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = "Units that must start after this service.";
      };

      wants = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = "Units wanted by this service.";
      };

      requires = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = "Units required by this service.";
      };

      bindsTo = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = "Units this service binds to.";
      };

      conflicts = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = "Units that conflict with this service.";
      };

      wantedBy = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = "Targets that want this service.";
      };

      requiredBy = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = "Targets that require this service.";
      };

      restartIfChanged = mkOption {
        type = types.bool;
        default = true;
        description = ''
          Whether to restart the service on switch when its unit changed.
          When false the service keeps running the old configuration until
          it is restarted by other means.
        '';
      };

      reloadIfChanged = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Whether to reload instead of restart the service on switch when its
          unit changed. Takes precedence over restartIfChanged.
        '';
      };

      stopIfChanged = mkOption {
        type = types.bool;
        default = true;
        description = ''
          Whether a changed service is stopped before activation and started
          afterwards. When false it is restarted after activation instead,
          which keeps it running across the activation script (useful for
          services such as sshd).
        '';
      };

      notSocketActivated = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Whether the switch engine must restart this service directly even if
          a socket of the same name exists, instead of restarting the socket.
        '';
      };

      restartTriggers = triggersOption "restart";
      reloadTriggers = triggersOption "reload";
      stopOnRemoval = stopOnRemovalOption;
      onlyManualStart = onlyManualStartOption;

      environment = mkOption {
        type = types.attrsOf types.str;
        default = { };
        description = "Environment variables for this service.";
      };

      path = mkOption {
        type = types.listOf types.package;
        default = [ ];
        description = "Packages to add to the service PATH.";
      };

      script = mkOption {
        type = types.nullOr types.lines;
        default = null;
        description = "Shell script to run as ExecStart.";
      };

      serviceConfig = mkOption {
        type = unitConfigType;
        default = { };
        description = "Systemd [Service] section options.";
      };
    };
  };

  # Type for a systemd socket unit
  socketOptions = {
    options = {
      description = mkOption {
        type = types.str;
        default = "";
        description = "Socket description.";
      };

      wantedBy = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = "Targets that want this socket.";
      };

      stopOnRemoval = stopOnRemovalOption;
      onlyManualStart = onlyManualStartOption;

      listenStreams = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = "Stream socket addresses to listen on.";
      };

      socketConfig = mkOption {
        type = unitConfigType;
        default = { };
        description = "Systemd [Socket] section options.";
      };
    };
  };

  # Type for a systemd target unit
  targetOptions = {
    options = {
      description = mkOption {
        type = types.str;
        default = "";
        description = "Target description.";
      };

      wants = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = "Units wanted by this target.";
      };

      requires = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = "Units required by this target.";
      };

      after = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = "Units that must start before this target.";
      };
    };
  };

  # Type for a systemd timer unit
  timerOptions = {
    options = {
      description = mkOption {
        type = types.str;
        default = "";
        description = "Timer description.";
      };

      wantedBy = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = "Targets that want this timer.";
      };

      stopOnRemoval = stopOnRemovalOption;
      onlyManualStart = onlyManualStartOption;

      timerConfig = mkOption {
        type = unitConfigType;
        default = { };
        description = "Systemd [Timer] section options.";
      };
    };
  };

  # Session variable value type — accepts string or list of strings
  sessionVarType = types.either types.str (types.listOf types.str);

  # Declarative enablement of a single unit file (keyed by unit file name).
  installLinkType = types.submodule {
    options = {
      wantedBy = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = "Units whose `.wants/` directory links to this unit.";
      };

      requiredBy = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = "Units whose `.requires/` directory links to this unit.";
      };
    };
  };

  # Build-time commands that populate one unit directory ("system" or "user")
  # of the /etc derivation: units shipped by packages, then the declarative
  # `.wants/` and `.requires/` links. Runs after all environment.etc entries
  # are in place, so generated units shadow packaged units of the same name.
  mkUnitTreeCommands =
    scope: links:
    let
      linkLines = concatStrings (
        mapAttrsToList (
          unit: l:
          concatMapStrings (
            t: "ekaosLinkUnit \"$unitDir\" wants ${escapeShellArg t} ${escapeShellArg unit}\n"
          ) (unique l.wantedBy)
          + concatMapStrings (
            t: "ekaosLinkUnit \"$unitDir\" requires ${escapeShellArg t} ${escapeShellArg unit}\n"
          ) (unique l.requiredBy)
        ) links
      );
    in
    ''
      unitDir="$out/etc/systemd/${scope}"
      mkdir -p "$unitDir"
      for pkg in ${concatMapStringsSep " " (p: escapeShellArg "${p}") cfg.packages}; do
        if [ -d "$pkg/lib/systemd/${scope}" ]; then
          ekaosLinkPackageUnits "$pkg/lib/systemd/${scope}" "$unitDir"
        fi
      done
      ${linkLines}
    '';

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
      ${switchKeys.unitLines name svc}

      [Service]
      ${switchKeys.serviceLines svc}
      ${optionalString (svc.script != null) "ExecStart=${execStart}"}
      ${concatStringsSep "\n" (
        mapAttrsToList (k: v: "${k}=${toString v}") (
          removeAttrs svc.serviceConfig [ "ExecStart" ]
          // optionalAttrs (svc.script == null && svc.serviceConfig ? ExecStart) {
            ExecStart = svc.serviceConfig.ExecStart;
          }
        )
      )}
      ${concatStringsSep "\n" envLines}
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
      ${switchKeys.unitLines name sock}

      [Socket]
      ${concatMapStringsSep "\n" (s: "ListenStream=${s}") sock.listenStreams}
      ${concatStringsSep "\n" (mapAttrsToList (k: v: "${k}=${toString v}") sock.socketConfig)}

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
      ${switchKeys.unitLines name tmr}

      [Timer]
      ${concatStringsSep "\n" (mapAttrsToList (k: v: "${k}=${toString v}") tmr.timerConfig)}

      [Install]
      ${concatMapStringsSep "\n" (t: "WantedBy=${t}") tmr.wantedBy}
    '';

  # Switch-engine settings for units this configuration does not generate
  # (units shipped by packages), written as drop-ins.
  switchOverrideOptions = {
    options = {
      restartIfChanged = mkOption {
        type = types.bool;
        default = true;
        description = "See systemd.services.<name>.restartIfChanged.";
      };
      reloadIfChanged = mkOption {
        type = types.bool;
        default = false;
        description = "See systemd.services.<name>.reloadIfChanged.";
      };
      stopIfChanged = mkOption {
        type = types.bool;
        default = true;
        description = "See systemd.services.<name>.stopIfChanged.";
      };
      stopOnReconfiguration = mkOption {
        type = types.bool;
        default = false;
        description = "Whether the switch engine stops this unit (usually a target) before activation.";
      };
      restartTriggers = triggersOption "restart";
      reloadTriggers = triggersOption "reload";
      stopOnRemoval = stopOnRemovalOption;
      onlyManualStart = onlyManualStartOption;
    };
  };

  mkSwitchOverride =
    unit: ov:
    let
      unitLines = switchKeys.unitLines unit ov;
      serviceLines = switchKeys.serviceLines ov;
    in
    pkgs.writeText "${unit}-ekaos-switch.conf" (
      optionalString (unitLines != "") ''
        [Unit]
        ${unitLines}
      ''
      + optionalString (hasSuffix ".service" unit && serviceLines != "") ''
        [Service]
        ${serviceLines}
      ''
    );

  # Filter to enabled services
  enabledSystemServices = filterAttrs (_: svc: svc.enable) cfg.services;
  enabledUserServices = filterAttrs (_: svc: svc.enable) cfg.user.services;

in

{
  options = {
    # Alias for systemd.defaultTarget (used by some ekapkgs modules)
    systemd.defaultUnit = mkOption {
      type = types.str;
      default = config.systemd.defaultTarget;
      description = "Alias for systemd.defaultTarget.";
    };

    # Packages that ship systemd unit files to be installed
    systemd.packages = mkOption {
      type = types.listOf types.package;
      default = [ ];
      description = ''
        Packages whose systemd unit files are installed to /etc/systemd/.
        Unit files are discovered from lib/systemd/system/ and
        lib/systemd/user/ within each package.
      '';
    };

    # Declarative enablement links, keyed by unit file name. Every module that
    # generates a unit with [Install] WantedBy=/RequiredBy= should also
    # register it here; [Install] alone has no effect without
    # `systemctl enable`.
    systemd.install = {
      system = mkOption {
        type = types.attrsOf installLinkType;
        default = { };
        internal = true;
        example = literalExpression ''{ "crond.service".wantedBy = [ "multi-user.target" ]; }'';
        description = ''
          Enablement links for system units, created as
          `/etc/systemd/system/<target>.wants/<unit>` (or `.requires/`).
        '';
      };

      user = mkOption {
        type = types.attrsOf installLinkType;
        default = { };
        internal = true;
        description = ''
          Enablement links for user units, created as
          `/etc/systemd/user/<target>.wants/<unit>` (or `.requires/`).
        '';
      };
    };

    # System services
    systemd.services = mkOption {
      type = types.attrsOf (types.submodule serviceOptions);
      default = { };
      description = "Systemd system service definitions.";
    };

    # Timers
    systemd.switchOverrides = mkOption {
      type = types.attrsOf (types.submodule switchOverrideOptions);
      default = { };
      example = literalExpression ''
        {
          "getty@.service".restartIfChanged = false;
          "dbus.service".reloadIfChanged = true;
          "local-fs.target".stopOnReconfiguration = true;
        }
      '';
      description = ''
        Switch-engine settings for system units that are not generated by
        this configuration, keyed by full unit name (templates apply to all
        instances). Each entry becomes the drop-in
        /etc/systemd/system/<unit>.d/50-ekaos-switch.conf.
      '';
    };

    systemd.timers = mkOption {
      type = types.attrsOf (types.submodule timerOptions);
      default = { };
      description = "Systemd timer definitions.";
    };

    # Tmpfiles
    systemd.tmpfiles = {
      packages = mkOption {
        type = types.listOf types.package;
        default = [ ];
        description = "Packages whose tmpfiles.d configuration should be installed.";
      };

      settings = mkOption {
        type = types.attrsOf types.anything;
        default = { };
        description = "Tmpfiles settings (name -> rule attrsets).";
      };
    };

    # User services, sockets, and targets
    systemd.user = {
      services = mkOption {
        type = types.attrsOf (types.submodule serviceOptions);
        default = { };
        description = "Systemd user service definitions.";
      };

      sockets = mkOption {
        type = types.attrsOf (types.submodule socketOptions);
        default = { };
        description = "Systemd user socket definitions.";
      };

      targets = mkOption {
        type = types.attrsOf (types.submodule targetOptions);
        default = { };
        description = "Systemd user target definitions (drop-ins).";
      };
    };

    # Session environment variables (set in user sessions via systemd environment.d)
    environment.sessionVariables = mkOption {
      type = types.attrsOf sessionVarType;
      default = { };
      example = literalExpression ''
        {
          EDITOR = "vim";
          GIO_EXTRA_MODULES = [ "''${pkgs.glib-networking}/lib/gio/modules" ];
        }
      '';
      description = ''
        Environment variables set in user login sessions.
        Values can be strings or lists of strings (joined with `:` as separator).
      '';
    };
  };

  config = {
    # Sync defaultUnit → defaultTarget
    systemd.defaultTarget = mkDefault cfg.defaultUnit;

    # Units shipped by systemd.packages are linked into the generated unit
    # trees at build time (see etcBuildCommands below).
    environment.etc = mkMerge [
      # Tmpfiles from packages
      (listToAttrs (
        concatMap (
          pkg:
          let
            tmpfilesDir = "${pkg}/lib/tmpfiles.d";
          in
          optional (builtins.pathExists tmpfilesDir) (
            nameValuePair "tmpfiles.d/${pkg.name}" {
              source = tmpfilesDir;
            }
          )
        ) cfg.tmpfiles.packages
      ))

      # Generated system service units
      (listToAttrs (
        mapAttrsToList (
          name: svc:
          nameValuePair "systemd/system/${name}.service" {
            source = mkServiceUnit name svc;
          }
        ) enabledSystemServices
      ))

      # Switch-engine drop-ins for package units
      (listToAttrs (
        mapAttrsToList (
          unit: ov:
          nameValuePair "systemd/system/${unit}.d/50-ekaos-switch.conf" {
            source = mkSwitchOverride unit ov;
          }
        ) cfg.switchOverrides
      ))

      # Generated system timer units
      (listToAttrs (
        mapAttrsToList (
          name: tmr:
          nameValuePair "systemd/system/${name}.timer" {
            source = mkTimerUnit name tmr;
          }
        ) cfg.timers
      ))

      # Generated user service units
      (listToAttrs (
        mapAttrsToList (
          name: svc:
          nameValuePair "systemd/user/${name}.service" {
            source = mkServiceUnit name svc;
          }
        ) enabledUserServices
      ))

      # Generated user socket units
      (listToAttrs (
        mapAttrsToList (
          name: sock:
          nameValuePair "systemd/user/${name}.socket" {
            source = mkSocketUnit name sock;
          }
        ) cfg.user.sockets
      ))

      # Generated user target drop-ins
      (listToAttrs (
        mapAttrsToList (
          name: tgt:
          nameValuePair "systemd/user/${name}.target.d/ekaos.conf" {
            source = mkTargetDropIn name tgt;
          }
        ) cfg.user.targets
      ))

      # Session variables via environment.d
      (mkIf (config.environment.sessionVariables != { }) {
        "environment.d/50-ekaos.conf".text = concatStringsSep "\n" (
          mapAttrsToList (
            name: value:
            let
              strValue = if isList value then concatStringsSep ":" value else toString value;
            in
            "${name}=${strValue}"
          ) config.environment.sessionVariables
        );
      })
    ];

    # Declarative enablement for the units generated by this module.
    systemd.install.system = mkMerge [
      (mapAttrs' (
        name: svc: nameValuePair "${name}.service" { inherit (svc) wantedBy requiredBy; }
      ) enabledSystemServices)
      (mapAttrs' (name: tmr: nameValuePair "${name}.timer" { inherit (tmr) wantedBy; }) cfg.timers)
    ];

    systemd.install.user = mkMerge [
      (mapAttrs' (
        name: svc: nameValuePair "${name}.service" { inherit (svc) wantedBy requiredBy; }
      ) enabledUserServices)
      (mapAttrs' (
        name: sock: nameValuePair "${name}.socket" { inherit (sock) wantedBy; }
      ) cfg.user.sockets)
    ];

    # Build the system and user unit trees inside the /etc derivation.
    environment.etcBuildCommands = ''
      # Link one enablement symlink: <dir>/<target>.<wants|requires>/<unit> -> ../<unit>
      ekaosLinkUnit() {
        mkdir -p "$1/$3.$2"
        ln -sfn "../$4" "$1/$3.$2/$4"
      }

      # Link units shipped by a package, without shadowing units already in
      # the tree. Packaged .wants/ and .requires/ directories are skipped so
      # that adding a package never enables units implicitly.
      ekaosLinkPackageUnits() {
        for unit in "$1"/*; do
          [ -e "$unit" ] || [ -L "$unit" ] || continue
          name=''${unit##*/}
          case "$name" in
            *.wants | *.requires) continue ;;
          esac
          if [ ! -e "$2/$name" ] && [ ! -L "$2/$name" ]; then
            ln -s "$unit" "$2/$name"
          fi
        done
      }

      ${mkUnitTreeCommands "system" cfg.install.system}
      ${mkUnitTreeCommands "user" cfg.install.user}
    '';

    system.activationScripts.systemd-units = stringAfter [ "etc" ] ''
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
}
