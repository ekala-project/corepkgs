# Adios port of ekaos/modules/hardware/nvidia.nix.
# TODO(adios-cutover) notes below mark semantics changed in translation.
{
  types,
  lib,
  pkgs,
  ...
}:
let
  # Local reimplementations of nixpkgs `lib.versionOlder`/`versionAtLeast`
  # (numeric comparison of "."-separated components).
  splitVersion = v: builtins.filter builtins.isString (builtins.split "\\." v);
  toNum =
    s:
    let
      m = builtins.match "([0-9]+).*" s;
    in
    if m == null then 0 else builtins.fromJSON (builtins.head m);
  cmpVersions =
    a: b:
    let
      pa = builtins.map toNum (splitVersion a);
      pb = builtins.map toNum (splitVersion b);
      len = if builtins.length pa > builtins.length pb then builtins.length pa else builtins.length pb;
      pad = l: l ++ builtins.genList (i: 0) (len - builtins.length l);
      za = pad pa;
      zb = pad pb;
      cmp = builtins.foldl' (
        acc: i:
        if acc != 0 then
          acc
        else if builtins.elemAt za i < builtins.elemAt zb i then
          -1
        else if builtins.elemAt za i > builtins.elemAt zb i then
          1
        else
          0
      ) 0 (builtins.genList (i: i) len);
    in
    cmp;
  versionOlder = a: b: cmpVersions a b == -1;
  versionAtLeast = a: b: cmpVersions a b != -1;

  busIDPattern = "([[:print:]]+:[0-9]{1,3}(@[0-9]{1,10})?:[0-9]{1,2}:[0-9])?";
in
{
  options = {
    enable = {
      type = types.bool;
      default = false;
      description = "Whether to enable NVIDIA proprietary driver support.";
    };

    package = {
      type = types.derivation;
      defaultFunc = { inputs, options }: inputs.kernel.kernelPackages.nvidiaPackages.${options.branch};
      description = ''
        The NVIDIA driver package to use.

        Prefer using {option}`hardware.nvidia.branch` when possible.
        If you set this, pick a package from
        `config.boot.kernelPackages.nvidiaPackages` so the driver build
        matches your configured kernel.
      '';
    };

    branch = {
      # TODO(adios-cutover): legacy type is a dynamic enum over
      # `builtins.attrNames (lib.filterAttrs (_: lib.isDerivation) nvidiaPackages)`;
      # dynamic enum validation lost, kept as a plain string.
      type = types.string;
      default = "stable";
      example = "production";
      description = ''
        The branch of the NVIDIA driver to use.

        Common branches: stable, production, latest, beta, vulkan_beta,
        legacy_535, legacy_470.
      '';
    };

    open = {
      type = types.nullOr types.bool;
      defaultFunc =
        { options, ... }:
        if versionOlder options.package.version "560" then false else null;
      example = true;
      description = ''
        Whether to use the open source NVIDIA kernel module.

        Recommended for Turing or later GPUs (RTX series, GTX 16xx).
        Use closed source modules for older GPUs.
      '';
    };

    modesettingEnable = {
      type = types.bool;
      defaultFunc = { options, ... }: versionAtLeast options.package.version "535";
      description = "Whether to enable kernel modesetting for the NVIDIA driver.";
    };

    gspEnable = {
      type = types.bool;
      defaultFunc =
        { options, ... }:
        options.open == true || versionAtLeast options.package.version "555";
      description = "Whether to enable GPU System Processor (GSP) firmware.";
    };

    powerManagementEnable = {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable NVIDIA power management through systemd (suspend/resume support).
      '';
    };

    powerManagementFinegrained = {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable fine-grained power management (PCI-Express Runtime D3).
        Requires PRIME offload to be enabled. Powers down the dGPU when idle.
      '';
    };

    dynamicBoostEnable = {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable Dynamic Boost to balance power between CPU and GPU on supported laptops.
      '';
    };

    primeNvidiaBusId = {
      type = types.string;
      default = "";
      example = "PCI:1:0:0";
      description = "Bus ID of the NVIDIA GPU.";
    };

    primeIntelBusId = {
      type = types.string;
      default = "";
      example = "PCI:0:2:0";
      description = "Bus ID of the Intel integrated GPU.";
    };

    primeAmdgpuBusId = {
      type = types.string;
      default = "";
      example = "PCI:4:0:0";
      description = "Bus ID of the AMD integrated GPU.";
    };

    primeOffloadEnable = {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable NVIDIA PRIME render offload. The dGPU renders only when explicitly
        requested via environment variables. Battery-friendly default for laptops.
      '';
    };

    primeSyncEnable = {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable NVIDIA PRIME sync mode. The dGPU is always on and handles all rendering.
        Outputs through the iGPU display outputs without a MUX.
      '';
    };

    primeReverseSyncEnable = {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable NVIDIA PRIME reverse sync. The iGPU handles rendering while the dGPU
        provides additional display outputs.
      '';
    };

    primeAllowExternalGpu = {
      type = types.bool;
      default = false;
      description = "Whether to enable external GPU (eGPU) support via Thunderbolt.";
    };

    nvidiaSettings = {
      type = types.bool;
      default = true;
      description = "Whether to enable nvidia-settings GUI configuration tool.";
    };

    nvidiaPersistenced = {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable nvidia-persistenced daemon to keep GPUs awake in headless mode.
      '';
    };
  };

  inputs = {
    kernel.from = { root }: root.boot.kernel;
    # Resolved: boot/kernel.nix exposes kernelPackages (default
    # pkgs.linux.pkgs), so inputs.kernel.kernelPackages is valid.
  };

  assertions = [
    {
      verify =
        { options }: (!options.enable) || (builtins.match busIDPattern options.primeNvidiaBusId != null);
      explain =
        { options }: "primeNvidiaBusId must be a PCI bus ID, got ${toString options.primeNvidiaBusId}";
    }
    {
      verify =
        { options }: (!options.enable) || (builtins.match busIDPattern options.primeIntelBusId != null);
      explain =
        { options }: "primeIntelBusId must be a PCI bus ID, got ${toString options.primeIntelBusId}";
    }
    {
      verify =
        { options }: (!options.enable) || (builtins.match busIDPattern options.primeAmdgpuBusId != null);
      explain =
        { options }: "primeAmdgpuBusId must be a PCI bus ID, got ${toString options.primeAmdgpuBusId}";
    }
    {
      verify = { options }: (!options.enable) || (options.open != null);
      explain = { options }: ''
        You must set hardware.nvidia.open on NVIDIA driver versions >= 560.
        Use true for Turing+ GPUs (RTX, GTX 16xx), false for older GPUs.
      '';
    }
    {
      verify = { options }: (!options.enable) || (!(options.open == true) || (options.package ? open));
      explain = { options }: "The selected NVIDIA package does not provide open kernel modules.";
    }
    {
      verify = { options }: (!options.enable) || (!(options.open == true) || options.gspEnable);
      explain = { options }: "GSP cannot be disabled when using the open source kernel driver.";
    }
    {
      verify =
        { options }:
        let
          primeEnabled =
            options.primeOffloadEnable || options.primeSyncEnable || options.primeReverseSyncEnable;
        in
        (!options.enable)
        || (
          primeEnabled
          ->
            options.primeNvidiaBusId != "" && (options.primeIntelBusId != "" || options.primeAmdgpuBusId != "")
        );
      explain = { options }: "When NVIDIA PRIME is enabled, GPU bus IDs must be configured.";
    }
    {
      verify =
        { options }: (!options.enable) || (!(options.primeSyncEnable && options.primeOffloadEnable));
      explain = { options }: "PRIME Sync and Offload cannot both be enabled.";
    }
    {
      verify =
        { options }: (!options.enable) || (!(options.primeSyncEnable && options.primeReverseSyncEnable));
      explain = { options }: "PRIME Sync and Reverse Sync cannot both be enabled.";
    }
    {
      verify =
        { options }:
        (!options.enable) || (!(options.primeSyncEnable && options.powerManagementFinegrained));
      explain = { options }: "Sync mode precludes powering down the NVIDIA GPU.";
    }
    {
      verify =
        { options }:
        (!options.enable) || (options.powerManagementFinegrained -> options.primeOffloadEnable);
      explain = { options }: "Fine-grained power management requires PRIME offload.";
    }
    {
      verify = { options }: (!options.enable) || (options.gspEnable -> (options.package ? firmware));
      explain = { options }: "This NVIDIA driver version does not provide GSP firmware.";
    }
  ];

  impl =
    { options, inputs }:
    let
      nvidia_x11 = options.package;
      useOpenModules = options.open == true;
    in
    if options.enable then
      lib.merge.attrs.recursively {
        mutators = [
          # Core driver configuration
          {
            # Blacklist conflicting modules
            boot.blacklistedKernelModules = [
              "nouveau"
              "nvidiafb"
            ];

            # Load nvidia-uvm lazily after udev rules are applied
            boot.extraModprobeConfig = ''
              softdep nvidia post: nvidia-uvm
            '';

            # Load nvidia-uvm eagerly for open modules (needed for CUDA)
            boot.kernelModules = [
              "nvidia"
              "nvidia_modeset"
              "nvidia_drm"
            ]
            ++ (if useOpenModules then [ "nvidia_uvm" ] else [ ]);

            # Install the kernel module
            boot.extraModulePackages = if useOpenModules then [ nvidia_x11.open ] else [ nvidia_x11 ];

            # Kernel modesetting for Wayland
            boot.kernelParams =
              (if options.modesettingEnable then [ "nvidia-drm.modeset=1" ] else [ ])
              ++ (
                if (options.modesettingEnable && versionAtLeast nvidia_x11.version "545") then
                  [
                    "nvidia-drm.fbdev=1"
                  ]
                else
                  [ ]
              );

            # udev rules for /dev/nvidia* device creation
            services.udev.extraRules = ''
              KERNEL=="nvidia", RUN+="${pkgs.runtimeShell} -c 'mknod -m 666 /dev/nvidiactl c 195 255'"
              KERNEL=="nvidia", RUN+="${pkgs.runtimeShell} -c 'for i in $$(cat /proc/driver/nvidia/gpus/*/information | grep Minor | cut -d \  -f 4); do mknod -m 666 /dev/nvidia$${i} c 195 $${i}; done'"
              KERNEL=="nvidia_modeset", RUN+="${pkgs.runtimeShell} -c 'mknod -m 666 /dev/nvidia-modeset c 195 254'"
              KERNEL=="nvidia_uvm", RUN+="${pkgs.runtimeShell} -c 'mknod -m 666 /dev/nvidia-uvm c $$(grep nvidia-uvm /proc/devices | cut -d \  -f 1) 0'"
              KERNEL=="nvidia_uvm", RUN+="${pkgs.runtimeShell} -c 'mknod -m 666 /dev/nvidia-uvm-tools c $$(grep nvidia-uvm /proc/devices | cut -d \  -f 1) 1'"
            '';

            # Graphics stack
            # TODO(adios-cutover): legacy mkDefault priority lost.
            hardware.graphics = {
              enable = true;
              enable32Bit = true;
              extraPackages = [ nvidia_x11.out ];
              extraPackages32 = [ nvidia_x11.lib32 ];
            };

            # GSP firmware
            hardware.firmware = if options.gspEnable then [ nvidia_x11.firmware ] else [ ];

            # Driver binaries (nvidia-smi, etc.)
            environment.systemPackages = [
              nvidia_x11.bin
            ]
            ++ (if options.nvidiaSettings then [ nvidia_x11.settings ] else [ ])
            ++ (if options.nvidiaPersistenced then [ nvidia_x11.persistenced ] else [ ]);
          }

          # Power management suspend/resume services
          (
            if options.powerManagementEnable then
              {
                boot.extraModprobeConfig = ''
                  options nvidia NVreg_PreserveVideoMemoryAllocations=1
                '';
              }
            else
              { }
          )

          # Fine-grained power management (RTD3) udev rules
          (
            if options.powerManagementFinegrained then
              {
                boot.extraModprobeConfig = ''
                  options nvidia NVreg_DynamicPowerManagement=0x02
                '';

                services.udev.extraRules = ''
                  # Enable runtime PM for NVIDIA VGA/3D controller devices on driver bind
                  ACTION=="bind", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x030000", TEST=="power/control", ATTR{power/control}="auto"
                  ACTION=="bind", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x030200", TEST=="power/control", ATTR{power/control}="auto"

                  # Disable runtime PM for NVIDIA VGA/3D controller devices on driver unbind
                  ACTION=="unbind", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x030000", TEST=="power/control", ATTR{power/control}="on"
                  ACTION=="unbind", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x030200", TEST=="power/control", ATTR{power/control}="on"
                '';
              }
            else
              { }
          )

          # PRIME offload convenience script
          (
            if options.primeOffloadEnable then
              {
                environment.systemPackages = [
                  (pkgs.writeShellScriptBin "nvidia-offload" ''
                    export __NV_PRIME_RENDER_OFFLOAD=1
                    export __NV_PRIME_RENDER_OFFLOAD_PROVIDER=NVIDIA-G0
                    export __GLX_VENDOR_LIBRARY_NAME=nvidia
                    export __VK_LAYER_NV_optimus=NVIDIA_only
                    exec "$@"
                  '')
                ];
              }
            else
              { }
          )

          # Reverse sync implies offloading
          # TODO(adios-cutover): legacy mkDefault priority lost.
          (
            if options.primeReverseSyncEnable then
              {
                hardware.nvidia.prime.offload.enable = true;
              }
            else
              { }
          )
        ];
      }
    else
      { };
}
