# Adios port of ekaos/modules/hardware/facter/firmware.nix.
# TODO(adios-cutover) notes below mark semantics changed in translation.
{ ... }:

{
  options = { };

  inputs = {
    facter.from = { root }: root.hardware.facter;
    virt.from = { root }: root.hardware.facter.virtualisation;
  };

  impl =
    { inputs, ... }:
    if (inputs.facter.enable && inputs.virt.noneEnable) then
      {
        # TODO(adios-cutover): legacy mkDefault priority lost.
        hardware.enableRedistributableFirmware = true;
      }
    else
      { };
}
