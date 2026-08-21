# Crash dump (kdump) configuration
# Reserves memory and configures kernel crash dumping
{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.boot.crashDump;
in

{
  options = {
    boot.crashDump = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Whether to enable kernel crash dumps (kdump).

          When enabled, memory is reserved for the crash kernel and
          the crashkernel parameter is added to the kernel command line.
        '';
      };

      reservedMemory = mkOption {
        type = types.str;
        default = "256M";
        example = "512M";
        description = ''
          Amount of memory reserved for the crash kernel.

          Uses the kernel crashkernel= syntax.
        '';
      };

      kernelParams = mkOption {
        type = types.listOf types.str;
        default = [ ];
        example = [
          "maxcpus=1"
          "nr_cpus=1"
        ];
        description = ''
          Additional kernel parameters for the crash kernel.
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    boot.kernelParams = [
      "crashkernel=${cfg.reservedMemory}"
    ];

    # TODO: add kexec-tools package when available
    environment.systemPackages = [
      (pkgs.kexec-tools or (builtins.trace "Warning: kexec-tools not available" pkgs.coreutils))
    ];
  };
}
