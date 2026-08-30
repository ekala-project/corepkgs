# Firmware update daemon
# Ported from nixpkgs/nixos/modules/services/hardware/fwupd.nix
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.fwupd;

  format = pkgs.formats.ini {
    listToValue = l: lib.concatStringsSep ";" (map (s: lib.generators.mkValueStringDefault { } s) l);
    mkKeyValue = lib.generators.mkKeyValueDefault { } "=";
  };

  fwupdConf = format.generate "fwupd.conf" (
    {
      fwupd = cfg.daemonSettings;
    }
    // lib.optionalAttrs (lib.length (lib.attrNames cfg.uefiCapsuleSettings) != 0) {
      uefi_capsule = cfg.uefiCapsuleSettings;
    }
  );

  originalEtc =
    let
      mkEtcFile = n: lib.nameValuePair n { source = "${cfg.package}/etc/${n}"; };
      etcFiles = cfg.package.filesInstalledToEtc or [ ];
    in
    lib.listToAttrs (map mkEtcFile etcFiles);

  extraTrustedKeys =
    let
      mkName = p: "pki/fwupd/${baseNameOf p}";
      mkEtcFile = p: lib.nameValuePair (mkName p) { source = p; };
    in
    lib.listToAttrs (map mkEtcFile cfg.extraTrustedKeys);

  enableRemote = base: remote: {
    "fwupd/remotes.d/${remote}.conf" = {
      source = pkgs.runCommand "${remote}-enabled.conf" { } ''
        sed "s,^Enabled=false,Enabled=true," \
        "${base}/etc/fwupd/remotes.d/${remote}.conf" > "$out"
      '';
    };
  };

  remotes = lib.foldl' (
    configFiles: remote: configFiles // (enableRemote cfg.package remote)
  ) { } cfg.extraRemotes;
in
{
  options.services.fwupd = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Whether to enable fwupd, a DBus service that allows
        applications to update firmware.
      '';
    };

    description = lib.mkOption {
      type = lib.types.str;
      default = "Firmware Update Daemon";
      description = "Service description.";
    };

    command = lib.mkOption {
      type = lib.types.str;
      internal = true;
      description = "Command to run (set automatically).";
    };

    args = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      internal = true;
      default = [ ];
      description = "Command arguments (set automatically).";
    };

    user = lib.mkOption {
      type = lib.types.str;
      default = "root";
      description = "User to run service as.";
    };

    restartPolicy = lib.mkOption {
      type = lib.types.str;
      default = "always";
      description = "Restart policy.";
    };

    systemd = lib.mkOption {
      type = lib.types.attrsOf lib.types.anything;
      default = { };
      description = "Systemd-specific options.";
    };

    extraTrustedKeys = lib.mkOption {
      type = lib.types.listOf lib.types.path;
      default = [ ];
      description = ''
        Installing a public key allows firmware signed with a matching
        private key to be recognized as trusted.
      '';
    };

    extraRemotes = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      example = [ "lvfs-testing" ];
      description = "Enables extra remotes in fwupd.";
    };

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.fwupd or (throw "fwupd package not available");
      defaultText = lib.literalExpression "pkgs.fwupd";
      description = "The fwupd package to use.";
    };

    daemonSettings = lib.mkOption {
      type = lib.types.submodule {
        freeformType = format.type.nestedTypes.elemType;
        options = {
          DisabledDevices = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [ ];
            description = "List of device GUIDs to be disabled.";
          };

          DisabledPlugins = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [ ];
            description = "List of plugins to be disabled.";
          };
        };
      };
      default = { };
      description = "Configurations for the fwupd daemon.";
    };

    uefiCapsuleSettings = lib.mkOption {
      type = lib.types.submodule {
        freeformType = format.type.nestedTypes.elemType;
      };
      default = { };
      description = "UEFI capsule configurations for the fwupd daemon.";
    };
  };

  config = lib.mkIf cfg.enable {
    services.fwupd = {
      command = "${cfg.package}/libexec/fwupd/fwupd";
      systemd = {
        after = [ "dbus.service" ];
        wantedBy = [ "multi-user.target" ];
      };
    };

    environment.systemPackages = [ cfg.package ];

    environment.etc =
      originalEtc
      // {
        "fwupd/fwupd.conf" = {
          source = fwupdConf;
        };
      }
      // extraTrustedKeys
      // remotes;

    services.dbus.packages = [ cfg.package ];

    # TODO: services.udev.packages not yet available in ekaOS
    # services.udev.packages = [ cfg.package ];

    users.users.fwupd-refresh = {
      isSystemUser = true;
      group = "fwupd-refresh";
      description = "Firmware update refresh user";
    };
    users.groups.fwupd-refresh = { };
  };
}
