# Adios port of ekaos/modules/hardware/facter/bluetooth-stack.nix.
# TODO(adios-cutover) notes below mark semantics changed in translation.
{ types, ... }:

{
  options = {
    stackEnable = {
      type = types.bool;
      defaultFunc =
        { inputs, ... }:
        builtins.length (inputs.facter.report.hardware.bluetooth or [ ]) > 0 && inputs.virt.noneEnable;
      description = "Whether to enable Facter Bluetooth stack.";
    };
  };

  inputs = {
    facter.from = { root }: root.hardware.facter;
    virt.from = { root }: root.hardware.facter.virtualisation;
  };

  impl =
    { options, inputs }:
    if (inputs.facter.enable && options.stackEnable) then
      {
        # TODO(adios-cutover): legacy mkDefault priority lost.
        hardware.bluetooth.enable = true;
      }
    else
      { };
}
