# Adios port of ekaos/modules/hardware/facter/thermal.nix.
# TODO(adios-cutover) notes below mark semantics changed in translation.
{ types, ... }:

{
  options = {
    enable = {
      type = types.bool;
      defaultFunc = { inputs, ... }: inputs.cpu.intelEnable && inputs.virt.noneEnable;
      description = "Whether to enable Facter thermal management.";
    };
  };

  inputs = {
    facter.from = { root }: root.hardware.facter;
    virt.from = { root }: root.hardware.facter.virtualisation;
    cpu.from = { root }: root.hardware.facter.cpu;
  };

  impl =
    { options, inputs }:
    if (inputs.facter.enable && options.enable) then
      {
        # TODO(adios-cutover): legacy mkDefault priority lost.
        services.thermald.enable = true;
      }
    else
      { };
}
