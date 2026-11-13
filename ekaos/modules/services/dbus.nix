# D-Bus system message bus
{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.services.dbus;

  configDir = pkgs.makeDBusConf.override {
    dbus = cfg.package;
    suidHelper = "${config.security.wrapperDir or "/run/wrappers/bin"}/dbus-daemon-launch-helper";
    serviceDirectories = cfg.packages;
  };

  useSystemd = config.serviceManager.systemd.enable;

in

{
  options.services.dbus = {
    enable = mkOption {
      type = types.bool;
      default = config.services.logind.enable;
      defaultText = literalExpression "config.services.logind.enable";
      description = ''
        Whether to start the D-Bus message bus daemon. Required by many
        system services including systemd-logind, NetworkManager,
        and PolicyKit, so it is on whenever logind is.
      '';
    };

    description = mkOption {
      type = types.str;
      default = "D-Bus System Message Bus";
      description = "Service description.";
    };

    command = mkOption {
      type = types.nullOr types.str;
      internal = true;
      # Stays null on systemd, which runs the upstream units instead
      default = null;
      description = "Command to run (set automatically).";
    };

    args = mkOption {
      type = types.listOf types.str;
      internal = true;
      default = [ ];
      description = "Command arguments (set automatically).";
    };

    user = mkOption {
      type = types.str;
      default = "root";
      description = "User to run service as.";
    };

    restartPolicy = mkOption {
      type = types.str;
      default = "always";
      description = "Restart policy.";
    };

    systemd = mkOption {
      type = types.attrsOf types.anything;
      default = { };
      description = "Systemd-specific options.";
    };

    package = mkOption {
      type = types.package;
      default = pkgs.dbus;
      description = "D-Bus package to use.";
    };

    packages = mkOption {
      type = types.listOf types.path;
      default = [ ];
      description = ''
        Packages whose D-Bus configuration files should be included.
        Files in «pkg»/etc/dbus-1/system.d, «pkg»/share/dbus-1/system.d,
        and «pkg»/share/dbus-1/system-services will be picked up.
      '';
    };
  };

  config = mkIf cfg.enable (mkMerge [
    # Without systemd, run the daemon as a portable service
    (mkIf (!useSystemd) {
      services.dbus = {
        command = "${cfg.package}/bin/dbus-daemon";
        args = [
          "--system"
          "--nofork"
          "--nopidfile"
          "--address=unix:path=/run/dbus/system_bus_socket"
        ];

        systemd = {
          after = [ "local-fs.target" ];
          wantedBy = [ "multi-user.target" ];
          # As in upstream's dbus.service
          serviceConfig.ExecReload = "${cfg.package}/bin/dbus-send --print-reply --system --type=method_call --dest=org.freedesktop.DBus / org.freedesktop.DBus.ReloadConfig";
        };
      };

    })

    # On systemd, use the upstream socket-activated units, so that units
    # ordered after dbus.socket (systemd-logind, ...) find the bus
    (mkIf useSystemd {
      environment.etc = {
        "systemd/system/dbus.socket".source = "${cfg.package}/etc/systemd/system/dbus.socket";
        "systemd/system/dbus.service".source = "${cfg.package}/etc/systemd/system/dbus.service";
        "systemd/system/sockets.target.wants/dbus.socket".source =
          "${cfg.package}/etc/systemd/system/dbus.socket";
      };
    })

    {
      # Restarting the system bus takes down everything attached to it. A
      # drop-in, so it holds for whichever dbus.service is installed.
      systemd.switchOverrides."dbus.service".reloadIfChanged = true;

      # Activation files and policies from the bus and the system profile
      services.dbus.packages = [
        cfg.package
        config.system.path
      ];

      # Install D-Bus configuration directory
      environment.etc."dbus-1".source = configDir;

      environment.pathsToLink = [
        "/etc/dbus-1"
        "/share/dbus-1"
      ];

      # Create messagebus user and group
      users.users.messagebus = {
        isSystemUser = true;
        uid = 4;
        group = "messagebus";
        description = "D-Bus system message bus daemon user";
      };
      users.groups.messagebus.gid = 4;

      # Add dbus tools to system packages
      environment.systemPackages = [ cfg.package ];

      # Create runtime directory
      system.activationScripts.dbus = stringAfter [ "etc" "users" ] ''
        mkdir -p /run/dbus
        chmod 755 /run/dbus
      '';
    }
  ]);
}
