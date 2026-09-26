# Adios port of ekaos/modules/hardware/facter/touchscreen.nix.
# TODO(adios-cutover) notes below mark semantics changed in translation.
{ types, lib, ... }:

{
  options = {
    enable = {
      type = types.bool;
      defaultFunc =
        { inputs, ... }:
        let
          facterLib = import ./lib.nix { };
          report = inputs.facter.report;
        in
        (builtins.length (report.hardware.touchscreen or [ ]) > 0 || facterLib.isConvertibleChassis report)
        && inputs.virt.noneEnable;
      description = "Whether to enable Facter touchscreen detection.";
    };

    convertibleEnable = {
      type = types.bool;
      defaultFunc =
        { inputs, ... }:
        let
          facterLib = import ./lib.nix { };
        in
        facterLib.isConvertibleChassis inputs.facter.report && inputs.virt.noneEnable;
      description = "Whether to enable Facter convertible/tablet detection.";
    };
  };

  inputs = {
    facter.from = { root }: root.hardware.facter;
    virt.from = { root }: root.hardware.facter.virtualisation;
  };

  impl =
    { options, inputs }:
    let
      facterLib = import ./lib.nix { };
    in
    if (inputs.facter.enable && options.enable) then
      lib.merge.attrs.recursively {
        mutators = [
          {
            # Load touchscreen driver modules
            boot.initrd.availableKernelModules = facterLib.unique (
              facterLib.collectDrivers (inputs.facter.report.hardware.touchscreen or [ ])
            );
          }

          # Ensure libinput handles touch input (Wayland/Hyprland);
          # hid-multitouch needed on convertibles
          (
            if options.convertibleEnable then
              {
                boot.kernelModules = [ "hid-multitouch" ];
              }
            else
              { }
          )
        ];
      }
    else
      { };
}
