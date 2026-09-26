# Adios port of ekaos/modules/hardware/facter/fwupd.nix.
# TODO(adios-cutover) notes below mark semantics changed in translation.
{ types, ... }:

{
  options = {
    enable = {
      type = types.bool;
      defaultFunc = { inputs, ... }: inputs.virt.noneEnable && inputs.boot.uefiSupported;
      description = "Whether to enable Facter firmware update support.";
    };
  };

  inputs = {
    facter.from = { root }: root.hardware.facter;
    virt.from = { root }: root.hardware.facter.virtualisation;
    boot.from = { root }: root.hardware.facter.boot;
  };

  impl =
    { options, inputs }:
    if (inputs.facter.enable && options.enable) then
      {
        # TODO(adios-cutover): legacy mkDefault priority lost.
        services.fwupd.enable = true;
      }
    else
      { };
}
