# Auto-detect virtualisation environment and configure accordingly
{
  lib,
  config,
  ...
}:
let
  inherit (config.hardware.facter) report;
  cfg = config.hardware.facter.detected.virtualisation;
in
{
  options.hardware.facter.detected.virtualisation = {
    virtio_scsi.enable = lib.mkEnableOption "Facter Virtio SCSI" // {
      default = lib.any (
        {
          vendor,
          device,
          ...
        }:
        # Red Hat, Inc. (0x1af4)
        (vendor.value or 0) == 6900
        &&
          # Virtio SCSI (0x1004, 0x1048)
          (lib.elem (device.value or 0) [
            4100
            4168
          ])
      ) (report.hardware.scsi or [ ]);
      defaultText = "hardware dependent";
    };

    qemu.enable = lib.mkEnableOption "Facter QEMU/KVM" // {
      default = builtins.elem (report.virtualisation or null) [
        "qemu"
        "kvm"
        "bochs"
      ];
      defaultText = "environment dependent";
    };

    none.enable = lib.mkEnableOption "Facter bare-metal" // {
      default = report.virtualisation or null == "none";
      defaultText = "environment dependent";
    };
  };

  config = lib.mkIf config.hardware.facter.enable {
    # KVM support — load kvm-intel or kvm-amd based on CPU features
    boot.kernelModules =
      let
        hasCPUFeature =
          feature: lib.any ({ features, ... }: lib.elem feature features) (report.hardware.cpu or [ ]);
      in
      lib.mkMerge [
        (lib.mkIf (hasCPUFeature "vmx") [ "kvm-intel" ])
        (lib.mkIf (hasCPUFeature "svm") [ "kvm-amd" ])
      ];

    # Virtio modules for QEMU/KVM guests
    boot.initrd = {
      kernelModules = lib.optionals cfg.qemu.enable [
        "virtio_balloon"
        "virtio_console"
        "virtio_rng"
        "virtio_gpu"
      ];

      availableKernelModules = lib.mkMerge [
        (lib.mkIf cfg.qemu.enable [
          "virtio_net"
          "virtio_pci"
          "virtio_mmio"
          "virtio_blk"
          "9p"
          "9pnet_virtio"
        ])
        (lib.mkIf cfg.virtio_scsi.enable [
          "virtio_scsi"
        ])
      ];
    };
  };
}
