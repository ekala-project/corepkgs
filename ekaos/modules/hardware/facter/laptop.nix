# Adios port of ekaos/modules/hardware/facter/laptop.nix.
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
        facterLib.isPortableChassis inputs.facter.report;
      description = "Whether to enable Facter portable device detection.";
    };
  };

  inputs = {
    facter.from = { root }: root.hardware.facter;
  };

  impl =
    { options, inputs }:
    if (inputs.facter.enable && options.enable) then
      {
        # On modern Intel HWP and AMD pstate, "powersave" still allows full
        # boost clocks — it just favors lower power states during idle
        # TODO(adios-cutover): legacy mkDefault priority lost (both options).
        power.cpuFreqGovernor = "powersave";

        # Auto-tune all power-saving knobs
        power.powertop.enable = true;
      }
    else
      { };
}
