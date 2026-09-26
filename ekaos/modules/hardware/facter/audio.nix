# Adios port of ekaos/modules/hardware/facter/audio.nix.
# TODO(adios-cutover) notes below mark semantics changed in translation.
{ types, lib, ... }:

{
  options = {
    enable = {
      type = types.bool;
      defaultFunc = { inputs, ... }: builtins.length (inputs.facter.report.hardware.sound or [ ]) > 0;
      description = "Whether to enable Facter audio hardware detection.";
    };

    kernelModules = {
      type = types.listOf types.string;
      defaultFunc =
        { inputs, ... }:
        let
          facterLib = import ./lib.nix { };
        in
        facterLib.unique (facterLib.collectDrivers (inputs.facter.report.hardware.sound or [ ]));
      description = "Kernel modules for detected audio hardware.";
    };

    sofEnable = {
      type = types.bool;
      defaultFunc =
        { inputs, ... }:
        let
          facterLib = import ./lib.nix { };
          driverModules = facterLib.collectDrivers (inputs.facter.report.hardware.sound or [ ]);
        in
        builtins.any (m: facterLib.hasPrefix "snd_sof" m || facterLib.hasPrefix "snd-sof" m) driverModules;
      description = "Whether to enable Facter Intel SOF audio detection.";
    };

    hdaEnable = {
      type = types.bool;
      defaultFunc =
        { inputs, ... }:
        let
          facterLib = import ./lib.nix { };
          driverModules = facterLib.collectDrivers (inputs.facter.report.hardware.sound or [ ]);
        in
        builtins.any (m: facterLib.hasPrefix "snd_hda" m || facterLib.hasPrefix "snd-hda" m) driverModules;
      description = "Whether to enable Facter Intel HDA audio detection.";
    };
  };

  inputs = {
    facter.from = { root }: root.hardware.facter;
  };

  impl =
    { options, inputs }:
    lib.merge.attrs.recursively {
      mutators = [
        # Load audio driver modules
        (
          if options.enable then
            {
              boot.initrd.availableKernelModules = options.kernelModules;
            }
          else
            { }
        )

        # Intel SOF audio: load additional SOF-specific modules
        (
          if (options.enable && options.sofEnable) then
            {
              boot.kernelModules = [
                "snd_sof"
                "snd_sof_pci"
                "snd_sof_intel_hda_common"
              ];
            }
          else
            { }
        )

        # Intel HDA audio
        (
          if (options.enable && options.hdaEnable) then
            {
              boot.kernelModules = [
                "snd_hda_intel"
              ];
            }
          else
            { }
        )
      ];
    };
}
