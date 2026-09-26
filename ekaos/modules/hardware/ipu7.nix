# Adios port of ekaos/modules/hardware/ipu7.nix.
# TODO(adios-cutover) notes below mark semantics changed in translation.
{ types, pkgs, ... }:

{
  options = {
    enable = {
      type = types.bool;
      default = false;
      description = "Whether to enable support for Intel IPU7/MIPI cameras (Lunar Lake).";
    };

    platform = {
      type = types.enum "ipu7Platform" [
        "ipu7x"
        "ipu75xa"
      ];
      default = "ipu7x";
      description = ''
        Choose the IPU version for your hardware platform.

        Use `ipu7x` for Lunar Lake and `ipu75xa` for Arrow Lake.
      '';
    };
  };

  inputs = {
    kernel.from = { root }: root.boot.kernel;
    # TODO(adios-cutover): `inputs.kernel.kernelPackages.ipu7-drivers`
    # assumes parent.boot.kernel exposes kernelPackages; verify against the
    # boot/kernel.nix port (the pilot only defines kernelParams,
    # kernelModules, consoleLogLevel).
  };

  impl =
    { options, inputs }:
    if options.enable then
      {
        # Load IPU7 kernel drivers
        boot.extraModulePackages = [ inputs.kernel.kernelPackages.ipu7-drivers ];

        # IPU7 firmware (lives under lib/firmware/intel/ipu/)
        hardware.firmware = [
          pkgs.ipu7-camera-bins
        ];

        # Restrict IPU7 raw nodes and media controller to root
        services.udev.extraRules = ''
          SUBSYSTEM=="intel-ipu7-psys", MODE="0660", GROUP="video"
          SUBSYSTEM=="media", DRIVERS=="intel-ipu7", MODE="0600", GROUP="root", TAG-="uaccess"
          SUBSYSTEM=="video4linux", DRIVERS=="intel-ipu7", MODE="0600", GROUP="root", TAG-="uaccess"
        '';

        # Camera HAL writes tuning data here
        tmpfiles.rules = [
          {
            type = "directory";
            path = "/run/camera";
            mode = "0755";
            user = "root";
            group = "video";
          }
        ];

        # Install the platform-specific camera HAL
        environment.systemPackages =
          let
            hal =
              {
                "ipu7x" = pkgs.ipu7-camera-hal;
                "ipu75xa" = pkgs.ipu75xa-camera-hal;
              }
              .${options.platform};
          in
          [ hal ];

        # TODO(corepkgs): Port v4l2-relayd and GStreamer icamerasrc plugin
        # for IPU7 to present the camera as a standard V4L2 device.
      }
    else
      { };
}
