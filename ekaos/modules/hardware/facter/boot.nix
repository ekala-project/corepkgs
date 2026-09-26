# Adios port of ekaos/modules/hardware/facter/boot.nix.
# TODO(adios-cutover) notes below mark semantics changed in translation.
{ types, ... }:

{
  options = {
    uefiSupported = {
      type = types.bool;
      defaultFunc = { inputs, ... }: inputs.facter.report.uefi.supported or false;
      description = "Whether to enable Facter UEFI detection.";
    };
  };

  inputs = {
    facter.from = { root }: root.hardware.facter;
  };

  impl =
    { options, inputs }:
    if (inputs.facter.enable && options.uefiSupported) then
      {
        # TODO(adios-cutover): legacy mkDefault priority lost (both options).
        boot.loader.systemd-boot.enable = true;
        boot.loader.efi.canTouchEfiVariables = true;
      }
    else
      { };
}
