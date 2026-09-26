# Adios port of ekaos/modules/config/coredump.nix.
# TODO(adios-cutover) notes below mark semantics changed in translation.
{
  types,
  lib,
  pkgs,
  ...
}:

let
  mkCoredumpConf =
    settings:
    pkgs.writeText "coredump.conf" (
      "[Coredump]\n"
      + builtins.concatStringsSep "\n" (
        builtins.map (k: "${k}=${toString settings.${k}}") (builtins.attrNames settings)
      )
      + "\n"
    );
in

{
  options = {
    enable = {
      type = types.bool;
      default = true;
      description = ''
        Whether core dumps should be processed by systemd-coredump.
        If disabled, core dumps appear in the current directory of the
        crashing process.
      '';
    };

    settings = {
      type = types.attrsOf (
        types.union [
          types.string
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

  impl =
    { options, ... }:
    let
      coredumpConf = mkCoredumpConf options.settings;
    in
    lib.merge.attrs.recursively {
      mutators = [
        (
          if options.enable then
            {
              environment.etc."systemd/coredump.conf".source = coredumpConf;
            }
          else
            { }
        )

        (
          if (!options.enable) then
            {
              # TODO(adios-cutover): priority lost (was mkDefault).
              boot.kernel.sysctl."kernel.core_pattern" = "core";
            }
          else
            { }
        )
      ];
    };
}
