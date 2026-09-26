# Adios port of ekaos/modules/hardware/facter/thunderbolt.nix.
# TODO(adios-cutover) notes below mark semantics changed in translation.
{ types, ... }:

{
  options = {
    enable = {
      type = types.bool;
      defaultFunc =
        { inputs, ... }:
        builtins.length (inputs.facter.report.hardware.thunderbolt_controller or [ ]) > 0
        && inputs.virt.noneEnable;
      description = "Whether to enable Facter Thunderbolt/USB4 detection.";
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
        # Load thunderbolt kernel module for device authorization
        boot.kernelModules = [ "thunderbolt" ];

        # Enable boltd for Thunderbolt device authorization
        # TODO(adios-cutover): legacy mkDefault priority lost.
        services.hardware.bolt.enable = true;
      }
    else
      { };
}
