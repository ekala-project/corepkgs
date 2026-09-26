# Adios port of ekaos/modules/hardware/ipu6.nix.
# TODO(adios-cutover) notes below mark semantics changed in translation.
{ types, pkgs, ... }:

{
  options = {
    enable = {
      type = types.bool;
      default = false;
      description = "Whether to enable support for Intel IPU6/MIPI cameras.";
    };

    platform = {
      type = types.enum "ipu6Platform" [
        "ipu6"
        "ipu6ep"
        "ipu6epmtl"
      ];
      # TODO(adios-cutover): legacy option has no default (required); no default set here.
      description = ''
        Choose the IPU version for your hardware platform.

        Use `ipu6` for Tiger Lake, `ipu6ep` for Alder Lake or Raptor Lake,
        and `ipu6epmtl` for Meteor Lake.
      '';
    };
  };

  inputs = {
    kernel.from = { root }: root.boot.kernel;
    # TODO(adios-cutover): `inputs.kernel.kernelPackages.ipu6-drivers`
    # assumes parent.boot.kernel exposes kernelPackages; verify against the
    # boot/kernel.nix port (the pilot only defines kernelParams,
    # kernelModules, consoleLogLevel).
  };

  impl =
    { options, inputs }:
    if options.enable then
      {
        # Load IPU6 kernel drivers (upstream since kernel 6.10, but still needs
        # out-of-tree i2c sensors and intel-ipu6-psys kernel driver)
        boot.extraModulePackages = [ inputs.kernel.kernelPackages.ipu6-drivers ];

        # IPU6 firmware and Intel Vision Sensing Controller firmware
        hardware.firmware = [
          pkgs.ipu6-camera-bins
          pkgs.ivsc-firmware
        ];

        # Restrict IPU6 raw nodes and media controller to root.
        # TAG-="uaccess" blocks logind ACL grants at login.
        services.udev.extraRules = ''
          SUBSYSTEM=="intel-ipu6-psys", MODE="0660", GROUP="video"
          SUBSYSTEM=="media", DRIVERS=="intel-ipu6", MODE="0600", GROUP="root", TAG-="uaccess"
          SUBSYSTEM=="video4linux", DRIVERS=="intel-ipu6", MODE="0600", GROUP="root", TAG-="uaccess"
        '';

        # ipu6-camera-hal writes AIQ tuning data and debug logs here
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
                "ipu6" = pkgs.ipu6-camera-hal;
                "ipu6ep" = pkgs.ipu6ep-camera-hal;
                "ipu6epmtl" = pkgs.ipu6epmtl-camera-hal;
              }
              .${options.platform};
          in
          [ hal ];

        # TODO(corepkgs): Port v4l2-relayd and configure v4l2loopback relay
        # for presenting IPU6 camera as a standard V4L2 device.
        # The full nixpkgs module uses services.v4l2-relay.instances.ipu6
        # with icamerasrc-{ipu6,ipu6ep,ipu6epmtl} GStreamer plugins.

        # TODO(corepkgs): Port WirePlumber configuration to disable raw IPU6
        # nodes so applications only see the v4l2loopback relay device.
      }
    else
      { };
}
