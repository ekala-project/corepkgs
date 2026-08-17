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

in

{
  options.services.dbus = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to start the D-Bus message bus daemon. Required by many
        system services including systemd-logind, NetworkManager,
        and PolicyKit.
      '';
    };

    description = mkOption {
      type = types.str;
      default = "D-Bus System Message Bus";
      description = "Service description.";
    };

    command = mkOption {
      type = types.str;
      internal = true;
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

  config = mkIf cfg.enable {
    services.dbus = {
      command = "${cfg.package}/bin/dbus-daemon";
      args = [
        "--system"
        "--nofork"
        "--nopidfile"
        "--address=unix:path=/run/dbus/system_bus_socket"
      ];

      packages = [
        cfg.package
        config.system.path
      ];

      systemd = {
        after = [ "local-fs.target" ];
        wantedBy = [ "multi-user.target" ];
      };
    };

    # Install D-Bus configuration directory
    environment.etc."dbus-1".source = configDir;

    environment.pathsToLink = [
      "/etc/dbus-1"
      "/share/dbus-1"
    ];

    # Create messagebus user and group
    users.users.messagebus = {
      isSystemUser = true;
      group = "messagebus";
      description = "D-Bus system message bus daemon user";
    };
    users.groups.messagebus = { };

    # Add dbus tools to system packages
    environment.systemPackages = [ cfg.package ];

    # Create runtime directory
    system.activationScripts.dbus = stringAfter [ "etc" "users" ] ''
      mkdir -p /run/dbus
      chmod 755 /run/dbus
    '';
  };
}
