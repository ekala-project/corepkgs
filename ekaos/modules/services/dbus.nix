# Adios port of ekaos/modules/services/dbus.nix.
# TODO(adios-cutover): command/args were internal options set by the legacy
# config; they are computed in impl, not user options.
{ types, pkgs, ... }:

{
  options = {
    enable = {
      type = types.bool;
      default = false;
      description = ''
        Whether to start the D-Bus message bus daemon. Required by many
        system services including systemd-logind, NetworkManager,
        and PolicyKit.
      '';
    };

    description = {
      type = types.string;
      default = "D-Bus System Message Bus";
      description = "Service description.";
    };

    user = {
      type = types.string;
      default = "root";
      description = "User to run service as.";
    };

    restartPolicy = {
      type = types.string;
      default = "always";
      description = "Restart policy.";
    };

    systemd = {
      type = types.attrsOf types.any;
      default = { };
      description = "Systemd-specific options.";
    };

    package = {
      type = types.derivation;
      default = pkgs.dbus;
      description = "D-Bus package to use.";
    };

    packages = {
      type = types.listOf types.pathLike;
      default = [ ];
      description = ''
        Packages whose D-Bus configuration files should be included.
        Files in «pkg»/etc/dbus-1/system.d, «pkg»/share/dbus-1/system.d,
        and «pkg»/share/dbus-1/system-services will be picked up.
      '';
    };
  };

  inputs = {
    # TODO(adios-cutover): verify tree path once the security batch lands
    # (legacy reads config.security.wrapperDir, defined in
    # security/wrappers/default.nix).
    security.from = { root }: root.security.wrappers;
    # TODO(adios-cutover): verify tree path once the system batch lands
    # (legacy reads config.system.path, defined in system/toplevel.nix).
    system.from = { root }: root.system.toplevel;
  };

  impl =
    { options, inputs }:
    if !options.enable then
      { }
    else
      let
        configDir = pkgs.makeDBusConf.override {
          dbus = options.package;
          suidHelper = "${inputs.security.wrapperDir or "/run/wrappers/bin"}/dbus-daemon-launch-helper";
          serviceDirectories = options.packages;
        };
      in
      {
        services.dbus = {
          inherit (options)
            enable
            description
            user
            restartPolicy
            ;
          command = "${options.package}/bin/dbus-daemon";
          args = [
            "--system"
            "--nofork"
            "--nopidfile"
            "--address=unix:path=/run/dbus/system_bus_socket"
          ];
          # Legacy list-merge: user packages ++ config packages.
          packages = options.packages ++ [
            options.package
            inputs.system.path
          ];
          systemd = {
            after = [ "local-fs.target" ];
            wantedBy = [ "multi-user.target" ];
          }
          // options.systemd;
        };

        environment.etc."dbus-1".source = configDir;

        environment.pathsToLink = [
          "/etc/dbus-1"
          "/share/dbus-1"
        ];

        users.users.messagebus = {
          isSystemUser = true;
          group = "messagebus";
          description = "D-Bus system message bus daemon user";
        };
        users.groups.messagebus = { };

        environment.systemPackages = [ options.package ];

        # TODO(adios-cutover): legacy ordering (after "etc" "users") lost; plain script.
        system.activationScripts.dbus = ''
          mkdir -p /run/dbus
          chmod 755 /run/dbus
        '';
      };
}
