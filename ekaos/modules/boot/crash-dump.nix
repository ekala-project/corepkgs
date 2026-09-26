# Adios port of ekaos/modules/boot/crash-dump.nix.
# TODO(adios-cutover) notes below mark semantics changed in translation.
{ types, pkgs, ... }:

{
  options = {
    enable = {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable kernel crash dumps (kdump).

        When enabled, memory is reserved for the crash kernel and
        the crashkernel parameter is added to the kernel command line.
      '';
    };

    reservedMemory = {
      type = types.string;
      default = "256M";
      example = "512M";
      description = ''
        Amount of memory reserved for the crash kernel.

        Uses the kernel crashkernel= syntax.
      '';
    };

    kernelParams = {
      type = types.listOf types.string;
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

  impl =
    { options, ... }:
    if !options.enable then
      { }
    else
      {
        boot.kernelParams = [
          "crashkernel=${options.reservedMemory}"
        ];

        environment.systemPackages = [
          (pkgs.kexec-tools or (builtins.trace "Warning: kexec-tools not available" pkgs.coreutils))
        ];
      };
  # Note: legacy config never consumes boot.crashDump.kernelParams; it is
  # accepted and exposed for other modules but has no effect here (same as
  # legacy). The kexec-tools fallback trace is preserved verbatim.
}
