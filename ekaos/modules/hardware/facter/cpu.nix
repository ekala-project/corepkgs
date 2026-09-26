# Adios port of ekaos/modules/hardware/facter/cpu.nix.
# TODO(adios-cutover) notes below mark semantics changed in translation.
{ types, lib, ... }:

{
  options = {
    amdEnable = {
      type = types.bool;
      defaultFunc =
        { inputs, ... }:
        let
          facterLib = import ./lib.nix { };
        in
        if inputs.facter.report == { } then false else facterLib.hasAmdCpu inputs.facter.report;
      description = "Whether to enable Facter AMD CPU detection.";
    };

    intelEnable = {
      type = types.bool;
      defaultFunc =
        { inputs, ... }:
        let
          facterLib = import ./lib.nix { };
        in
        if inputs.facter.report == { } then false else facterLib.hasIntelCpu inputs.facter.report;
      description = "Whether to enable Facter Intel CPU detection.";
    };
  };

  inputs = {
    facter.from = { root }: root.hardware.facter;
    virt.from = { root }: root.hardware.facter.virtualisation;
    hw.from = { root }: root.hardware.firmware;
  };

  impl =
    { options, inputs }:
    lib.merge.attrs.recursively {
      mutators = [
        # AMD microcode updates
        (
          if (options.amdEnable && inputs.virt.noneEnable) then
            {
              # TODO(adios-cutover): legacy mkDefault priority lost.
              hardware.cpu.amd.updateMicrocode = inputs.hw.enableRedistributableFirmware;
              # amd-pstate active mode for modern frequency scaling (kernel 6.3+)
              boot.kernelParams = [ "amd_pstate=active" ];
            }
          else
            { }
        )

        # Intel microcode updates
        (
          if (options.intelEnable && inputs.virt.noneEnable) then
            {
              # TODO(adios-cutover): legacy mkDefault priority lost.
              hardware.cpu.intel.updateMicrocode = inputs.hw.enableRedistributableFirmware;
            }
          else
            { }
        )
      ];
    };
}
