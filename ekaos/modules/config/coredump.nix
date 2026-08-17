# Systemd coredump configuration
{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.systemd.coredump;

  coredumpConf = pkgs.writeText "coredump.conf" (
    "[Coredump]\n"
    + concatStringsSep "\n" (mapAttrsToList (k: v: "${k}=${toString v}") cfg.settings)
    + "\n"
  );

in

{
  options.systemd.coredump = {
    enable = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Whether core dumps should be processed by systemd-coredump.
        If disabled, core dumps appear in the current directory of the
        crashing process.
      '';
    };

    settings = mkOption {
      type = types.attrsOf (
        types.oneOf [
          types.str
          types.int
          types.bool
        ]
      );
      default = { };
      example = {
        Storage = "journal";
        MaxUse = "1G";
        ProcessSizeMax = "2G";
      };
      description = ''
        Settings for systemd-coredump written to /etc/systemd/coredump.conf.
        See coredump.conf(5) for available options.

        Common settings:
        - Storage: where to store core dumps (none, external, journal)
        - Compress: whether to compress stored core dumps (default: yes)
        - MaxUse: maximum disk space for stored core dumps
        - ProcessSizeMax: maximum size of core dump to process
      '';
    };
  };

  config = mkMerge [
    (mkIf cfg.enable {
      environment.etc."systemd/coredump.conf".source = coredumpConf;
    })

    (mkIf (!cfg.enable) {
      boot.kernel.sysctl."kernel.core_pattern" = mkDefault "core";
    })
  ];
}
