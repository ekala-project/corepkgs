# Adios port of ekaos/modules/hardware/facter/camera.nix.
# TODO(adios-cutover) notes below mark semantics changed in translation.
{ types, lib, ... }:
let
  # PCI IDs used by the detection defaults below.
  intelVendorId = 32902;
  tigerLakeId = 39449; # 0x9a19
  alderLakeId = 18013; # 0x465d
  raptorLakeId = 42845; # 0xa75d
  meteorLakeId = 32025; # 0x7d19
  lunarLakeId = 25693; # 0x645d
  arrowLakeId = 45149; # 0xb05d

  findIntelDevice =
    ids: devices:
    let
      found = builtins.filter (
        {
          vendor ? { },
          device ? { },
          ...
        }:
        (vendor.value or 0) == intelVendorId && builtins.elem (device.value or 0) ids
      ) devices;
    in
    if found == [ ] then null else builtins.head found;

  detectIpu6Platform =
    report:
    let
      ipu6Device = findIntelDevice [ tigerLakeId alderLakeId raptorLakeId meteorLakeId ] (
        report.hardware.multimedia_controller or [ ]
      );
      ipu6DeviceId = if ipu6Device != null then (ipu6Device.device.value or 0) else 0;
    in
    {
      hasIpu6 = ipu6Device != null;
      platform =
        if ipu6DeviceId == tigerLakeId then
          "ipu6"
        else if ipu6DeviceId == alderLakeId || ipu6DeviceId == raptorLakeId then
          "ipu6ep"
        else if ipu6DeviceId == meteorLakeId then
          "ipu6epmtl"
        else
          "ipu6";
    };

  detectIpu7Platform =
    report:
    let
      ipu7Device = findIntelDevice [ lunarLakeId arrowLakeId ] (
        report.hardware.multimedia_controller or [ ]
      );
      ipu7DeviceId = if ipu7Device != null then (ipu7Device.device.value or 0) else 0;
    in
    {
      hasIpu7 = ipu7Device != null;
      platform = if ipu7DeviceId == arrowLakeId then "ipu75xa" else "ipu7x";
    };
in
{
  options = {
    ipu6Enable = {
      type = types.bool;
      defaultFunc = { inputs, ... }: (detectIpu6Platform inputs.facter.report).hasIpu6;
      description = "Whether to enable Facter Intel IPU6 camera detection.";
    };

    ipu6Platform = {
      type = types.enum "ipu6Platform" [
        "ipu6"
        "ipu6ep"
        "ipu6epmtl"
      ];
      defaultFunc = { inputs, ... }: (detectIpu6Platform inputs.facter.report).platform;
      description = "Auto-detected IPU6 platform variant based on CPU generation.";
    };

    ipu7Enable = {
      type = types.bool;
      defaultFunc = { inputs, ... }: (detectIpu7Platform inputs.facter.report).hasIpu7;
      description = "Whether to enable Facter Intel IPU7 camera detection.";
    };

    ipu7Platform = {
      type = types.enum "ipu7Platform" [
        "ipu7x"
        "ipu75xa"
      ];
      defaultFunc = { inputs, ... }: (detectIpu7Platform inputs.facter.report).platform;
      description = "Auto-detected IPU7 platform variant.";
    };
  };

  inputs = {
    facter.from = { root }: root.hardware.facter;
  };

  impl =
    { options, inputs }:
    lib.merge.attrs.recursively {
      mutators = [
        (
          if options.ipu6Enable then
            {
              # TODO(adios-cutover): legacy mkDefault priority lost (both options).
              hardware.ipu6.enable = true;
              hardware.ipu6.platform = options.ipu6Platform;
            }
          else
            { }
        )

        (
          if options.ipu7Enable then
            {
              # TODO(adios-cutover): legacy mkDefault priority lost (both options).
              hardware.ipu7.enable = true;
              hardware.ipu7.platform = options.ipu7Platform;
            }
          else
            { }
        )
      ];
    };
}
