# Adios port of ekaos/modules/services/hardware/fwupd.nix.
# TODO(adios-cutover): command/args were internal options set by the legacy
# config; they are computed in impl, not user options.
# TODO(adios-cutover): daemonSettings/uefiCapsuleSettings used an INI
# freeformType (arbitrary extra keys allowed); only the known leaves are
# modelled here and extra freeform keys are lost.
{ types, pkgs, ... }:

{
  options = {
    enable = {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable fwupd, a DBus service that allows
        applications to update firmware.
      '';
    };

    description = {
      type = types.string;
      default = "Firmware Update Daemon";
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

    extraTrustedKeys = {
      type = types.listOf types.pathLike;
      default = [ ];
      description = ''
        Installing a public key allows firmware signed with a matching
        private key to be recognized as trusted.
      '';
    };

    extraRemotes = {
      type = types.listOf types.string;
      default = [ ];
      description = "Enables extra remotes in fwupd.";
    };

    package = {
      type = types.nullOr types.derivation;
      default = pkgs.fwupd or null;
      description = "The fwupd package to use.";
    };

    daemonSettings = {
      options = {
        DisabledDevices = {
          type = types.listOf types.string;
          default = [ ];
          description = "List of device GUIDs to be disabled.";
        };

        DisabledPlugins = {
          type = types.listOf types.string;
          default = [ ];
          description = "List of plugins to be disabled.";
        };
      };
      description = "Configurations for the fwupd daemon.";
    };

    uefiCapsuleSettings = {
      type = types.attrs;
      default = { };
      description = "UEFI capsule configurations for the fwupd daemon.";
    };
  };

  assertions = [
    {
      verify = { options, ... }: (!options.enable) || (options.package != null);
      explain = { options, ... }: "package option must be set when enabled (fwupd is not in core-pkgs)";
    }
  ];

  impl =
    { options, ... }:
    if !options.enable then
      { }
    else
      let
        # Minimal local replacement for the lib.generators helpers the legacy
        # module passed to pkgs.formats.ini.
        mkIniValue =
          v:
          if builtins.isBool v then
            (if v then "true" else "false")
          else if builtins.isList v then
            builtins.concatStringsSep ";" (builtins.map mkIniValue v)
          else
            toString v;

        format = pkgs.formats.ini {
          listToValue = l: builtins.concatStringsSep ";" (builtins.map mkIniValue l);
          mkKeyValue = k: v: "${k}=${mkIniValue v}";
        };

        daemonSettings = options.daemonSettings or { };

        fwupdConf = format.generate "fwupd.conf" (
          {
            fwupd = {
              DisabledDevices = daemonSettings.DisabledDevices or [ ];
              DisabledPlugins = daemonSettings.DisabledPlugins or [ ];
            };
          }
          // (
            if builtins.length (builtins.attrNames (options.uefiCapsuleSettings or { })) != 0 then
              {
                uefi_capsule = options.uefiCapsuleSettings;
              }
            else
              { }
          )
        );

        originalEtc =
          let
            mkEtcFile = n: {
              name = n;
              value = {
                source = "${options.package}/etc/${n}";
              };
            };
            etcFiles = options.package.filesInstalledToEtc or [ ];
          in
          builtins.listToAttrs (builtins.map mkEtcFile etcFiles);

        extraTrustedKeys =
          let
            mkName = p: "pki/fwupd/${baseNameOf p}";
            mkEtcFile = p: {
              name = mkName p;
              value = {
                source = p;
              };
            };
          in
          builtins.listToAttrs (builtins.map mkEtcFile (options.extraTrustedKeys or [ ]));

        enableRemote = base: remote: {
          "fwupd/remotes.d/${remote}.conf" = {
            source = pkgs.runCommand "${remote}-enabled.conf" { } ''
              sed "s,^Enabled=false,Enabled=true," \
              "${base}/etc/fwupd/remotes.d/${remote}.conf" > "$out"
            '';
          };
        };

        remotes = builtins.foldl' (
          configFiles: remote: configFiles // (enableRemote options.package remote)
        ) { } (options.extraRemotes or [ ]);
      in
      {
        services.fwupd = {
          inherit (options)
            enable
            description
            user
            restartPolicy
            ;
          command = "${options.package}/libexec/fwupd/fwupd";
          args = [ ];
          systemd = {
            after = [ "dbus.service" ];
            wantedBy = [ "multi-user.target" ];
          }
          // options.systemd;
        };

        environment.systemPackages = [ options.package ];

        environment.etc =
          originalEtc
          // {
            "fwupd/fwupd.conf" = {
              source = fwupdConf;
            };
          }
          // extraTrustedKeys
          // remotes;

        services.dbus.packages = [ options.package ];

        services.udev.packages = [ options.package ];

        users.users.fwupd-refresh = {
          isSystemUser = true;
          group = "fwupd-refresh";
          description = "Firmware update refresh user";
        };
        users.groups.fwupd-refresh = { };
      };
}
