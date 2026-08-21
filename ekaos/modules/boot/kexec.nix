# kexec — fast kernel reboot
{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.boot.kexec;
in

{
  options = {
    boot.kexec = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Whether to enable kexec support for fast reboots.

          kexec loads a new kernel into memory and reboots into it
          without going through BIOS/UEFI, significantly reducing
          reboot time.
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    # TODO: requires kexec-tools package
    environment.systemPackages = [
      (pkgs.kexec-tools or (builtins.trace "Warning: kexec-tools not available" pkgs.coreutils))
    ];
  };
}
