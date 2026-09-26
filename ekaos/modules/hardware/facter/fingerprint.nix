# Adios port of ekaos/modules/hardware/facter/fingerprint.nix.
# TODO(adios-cutover) notes below mark semantics changed in translation.
{ types, ... }:

{
  options = {
    enable = {
      type = types.bool;
      defaultFunc =
        { inputs, ... }:
        builtins.length (inputs.facter.report.hardware.fingerprint_reader or [ ]) > 0
        && inputs.virt.noneEnable;
      description = "Whether to enable Facter fingerprint reader detection.";
    };
  };

  inputs = {
    facter.from = { root }: root.hardware.facter;
    virt.from = { root }: root.hardware.facter.virtualisation;
  };

  impl =
    { options, inputs }:
    if (inputs.facter.enable && options.enable) then
      {
        # TODO(adios-cutover): legacy mkDefault priority lost.
        services.fprintd.enable = true;
      }
    else
      { };
}
