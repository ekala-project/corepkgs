# Adios port of ekaos/modules/boot/kexec.nix.
# TODO(adios-cutover) notes below mark semantics changed in translation.
{ types, pkgs, ... }:

{
  options = {
    enable = {
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

  impl =
    { options, ... }:
    if !options.enable then
      { }
    else
      {
        environment.systemPackages = [
          (pkgs.kexec-tools or (builtins.trace "Warning: kexec-tools not available" pkgs.coreutils))
        ];
      };
}
