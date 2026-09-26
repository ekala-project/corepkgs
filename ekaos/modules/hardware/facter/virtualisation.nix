# Adios port of ekaos/modules/hardware/facter/virtualisation.nix.
# TODO(adios-cutover) notes below mark semantics changed in translation.
{ types, lib, ... }:

{
  options = {
    virtioScsiEnable = {
      type = types.bool;
      defaultFunc =
        { inputs, ... }:
        builtins.any (
          {
            vendor,
            device,
            ...
          }:
          # Red Hat, Inc. (0x1af4)
          (vendor.value or 0) == 6900
          &&
            # Virtio SCSI (0x1004, 0x1048)
            (builtins.elem (device.value or 0) [
              4100
              4168
            ])
        ) (inputs.facter.report.hardware.scsi or [ ]);
      description = "Whether to enable Facter Virtio SCSI.";
    };

    qemuEnable = {
      type = types.bool;
      defaultFunc =
        { inputs, ... }:
        builtins.elem (inputs.facter.report.virtualisation or null) [
          "qemu"
          "kvm"
          "bochs"
        ];
      description = "Whether to enable Facter QEMU/KVM.";
    };

    noneEnable = {
      type = types.bool;
      defaultFunc = { inputs, ... }: inputs.facter.report.virtualisation or null == "none";
      description = "Whether to enable Facter bare-metal.";
    };
  };

  inputs = {
    facter.from = { root }: root.hardware.facter;
  };

  impl =
    { options, inputs }:
    let
      hasCPUFeature =
        feature:
        builtins.any ({ features, ... }: builtins.elem feature features) (
          inputs.facter.report.hardware.cpu or [ ]
        );
    in
    if inputs.facter.enable then
      lib.merge.attrs.recursively {
        mutators = [
          {
            # KVM support — load kvm-intel or kvm-amd based on CPU features
            boot.kernelModules =
              (if hasCPUFeature "vmx" then [ "kvm-intel" ] else [ ])
              ++ (if hasCPUFeature "svm" then [ "kvm-amd" ] else [ ]);
          }

          # KSM deduplicates identical memory pages — valuable for KVM hosts
          # running multiple VMs with similar guest OS images
          # TODO(adios-cutover): legacy `lib.mkIf cfg.none.enable (lib.mkDefault true)`
          # priority lost; translated as conditional fragment.
          (
            if options.noneEnable then
              {
                hardware.ksm.enable = true;
              }
            else
              { }
          )

          {
            # Virtio modules for QEMU/KVM guests
            boot.initrd = {
              kernelModules =
                if options.qemuEnable then
                  [
                    "virtio_balloon"
                    "virtio_console"
                    "virtio_rng"
                    "virtio_gpu"
                  ]
                else
                  [ ];

              availableKernelModules =
                (
                  if options.qemuEnable then
                    [
                      "virtio_net"
                      "virtio_pci"
                      "virtio_mmio"
                      "virtio_blk"
                      "9p"
                      "9pnet_virtio"
                    ]
                  else
                    [ ]
                )
                ++ (
                  if options.virtioScsiEnable then
                    [
                      "virtio_scsi"
                    ]
                  else
                    [ ]
                );
            };
          }
        ];
      }
    else
      { };
}
