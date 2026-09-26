# Adios port of ekaos/modules/hardware/facter/trackpoint.nix.
# TODO(adios-cutover) notes below mark semantics changed in translation.
{ types, ... }:

{
  options = {
    enable = {
      type = types.bool;
      defaultFunc =
        { inputs, ... }:
        let
          facterLib = import ./lib.nix { };
        in
        facterLib.isThinkPad inputs.facter.report;
      description = "Whether to enable Facter TrackPoint detection.";
    };
  };

  inputs = {
    facter.from = { root }: root.hardware.facter;
  };

  impl =
    { options, inputs }:
    if (inputs.facter.enable && options.enable) then
      {
        # TODO(adios-cutover): legacy mkDefault priority lost (both options).
        hardware.trackpoint.enable = true;
        hardware.trackpoint.emulateWheel = true;
      }
    else
      { };
}
