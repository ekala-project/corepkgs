{
  pkgs,
  # This is meant to be be a list of overlays
  # TODO(corepkgs): make a config.overlays.linux
  kernelPackagesExtensions ? [ ],
  config,
  buildPackages,
  stdenv,
  stdenvNoCC,
  newScope,
  lib,
  fetchurl,
}:

# When adding a kernel:
# - Update packageAliases.linux_latest to the latest version
# - Update linux_latest_hardened when the patches become available

let
  inherit (lib) recurseIntoAttrs dontRecurseIntoAttrs;

  markBroken =
    drv:
    drv.overrideAttrs (
      {
        meta ? { },
        ...
      }:
      {
        meta = meta // {
          broken = true;
        };
      }
    );

  kernelPatches = pkgs.callFromScope ./kernel/patches.nix { };

  # Hardened Linux
  hardenedKernelFor =
    kernel': overrides:
    let
      kernel = kernel'.override overrides;
      version = kernelPatches.hardened.${kernel.meta.branch}.version;
      major = lib.versions.major version;
      sha256 = kernelPatches.hardened.${kernel.meta.branch}.sha256;
      modDirVersion' = builtins.replaceStrings [ kernel.version ] [ version ] kernel.modDirVersion;
    in
    kernel.override {
      structuredExtraConfig = import ./kernel/hardened/config.nix {
        inherit stdenv lib version;
      };
      argsOverride = {
        inherit version;
        pname = "linux-hardened";
        modDirVersion = modDirVersion' + kernelPatches.hardened.${kernel.meta.branch}.extra;
        src = fetchurl {
          url = "mirror://kernel/linux/kernel/v${major}.x/linux-${version}.tar.xz";
          inherit sha256;
        };
        extraMeta = {
          broken = kernel.meta.broken;
        };
      };
      kernelPatches = kernel.kernelPatches ++ [
        kernelPatches.hardened.${kernel.meta.branch}
      ];
      isHardened = true;
    };
in

# TODO (corepkgs): make into spliced scope for cross compilation
lib.makeScope pkgs.newScope (
  linux: with linux; {
    inherit kernelPatches;

    buildLinux = callPackage ./kernel/generic.nix { };

    kernels =
      recurseIntoAttrs {
        # NOTE: PLEASE DO NOT ADD NEW DOWNSTREAM KERNELS TO NIXPKGS.
        # New vendor kernels should go to nixos-hardware instead.
        # e.g. https://github.com/NixOS/nixos-hardware/tree/master/microsoft/surface/kernel

        linux_rpi1 = callPackage ./kernel/linux-rpi.nix {
          kernelPatches = with kernelPatches; [
            bridge_stp_helper
            request_key_helper
          ];
          rpiVersion = 1;
        };

        linux_rpi2 = callPackage ./kernel/linux-rpi.nix {
          kernelPatches = with kernelPatches; [
            bridge_stp_helper
            request_key_helper
          ];
          rpiVersion = 2;
        };

        linux_rpi3 = callPackage ./kernel/linux-rpi.nix {
          kernelPatches = with kernelPatches; [
            bridge_stp_helper
            request_key_helper
          ];
          rpiVersion = 3;
        };

        linux_rpi4 = callPackage ./kernel/linux-rpi.nix {
          kernelPatches = with kernelPatches; [
            bridge_stp_helper
            request_key_helper
          ];
          rpiVersion = 4;
        };

        linux_5_10 = callPackage ./kernel/mainline.nix {
          branch = "5.10";
          kernelPatches = [
            kernelPatches.bridge_stp_helper
            kernelPatches.request_key_helper
          ];
        };

        linux_rt_5_10 = callPackage ./kernel/linux-rt-5.10.nix {
          kernelPatches = [
            kernelPatches.bridge_stp_helper
            kernelPatches.request_key_helper
            kernelPatches.export-rt-sched-migrate
          ];
        };

        linux_5_15 = callPackage ./kernel/mainline.nix {
          branch = "5.15";
          kernelPatches = [
            kernelPatches.bridge_stp_helper
            kernelPatches.request_key_helper
          ];
        };

        linux_rt_5_15 = callPackage ./kernel/linux-rt-5.15.nix {
          kernelPatches = [
            kernelPatches.bridge_stp_helper
            kernelPatches.request_key_helper
            kernelPatches.export-rt-sched-migrate
          ];
        };

        linux_6_1 = callPackage ./kernel/mainline.nix {
          branch = "6.1";
          kernelPatches = [
            kernelPatches.bridge_stp_helper
            kernelPatches.request_key_helper
          ];
        };

        linux_rt_6_1 = callPackage ./kernel/linux-rt-6.1.nix {
          kernelPatches = [
            kernelPatches.bridge_stp_helper
            kernelPatches.request_key_helper
            kernelPatches.export-rt-sched-migrate
          ];
        };

        linux_6_6 = callPackage ./kernel/mainline.nix {
          branch = "6.6";
          kernelPatches = [
            kernelPatches.bridge_stp_helper
            kernelPatches.request_key_helper
          ];
        };

        linux_rt_6_6 = callPackage ./kernel/linux-rt-6.6.nix {
          kernelPatches = [
            kernelPatches.bridge_stp_helper
            kernelPatches.request_key_helper
            kernelPatches.export-rt-sched-migrate
          ];
        };

        linux_6_12 = callPackage ./kernel/mainline.nix {
          branch = "6.12";
          kernelPatches = [
            kernelPatches.bridge_stp_helper
            kernelPatches.request_key_helper
          ];
        };

        linux_6_17 = callPackage ./kernel/mainline.nix {
          branch = "6.17";
          kernelPatches = [
            kernelPatches.bridge_stp_helper
            kernelPatches.request_key_helper
          ];
        };

        linux_6_18 = callPackage ./kernel/mainline.nix {
          branch = "6.18";
          kernelPatches = [
            kernelPatches.bridge_stp_helper
            kernelPatches.request_key_helper
          ];
        };

        linux_testing =
          let
            testing = callPackage ./kernel/mainline.nix {
              # A special branch that tracks the kernel under the release process
              # i.e. which has at least a public rc1 and is not released yet.
              branch = "testing";
              kernelPatches = [
                kernelPatches.bridge_stp_helper
                kernelPatches.request_key_helper
              ];
            };
            latest = packageAliases.linux_latest.kernel;
          in
          if latest.kernelAtLeast testing.baseVersion then latest else testing;

        linux_default = packageAliases.linux_default.kernel;

        linux_latest = packageAliases.linux_latest.kernel;

        # Using zenKernels like this due lqx&zen came from one source, but may have different base kernel version
        # https://github.com/NixOS/nixpkgs/pull/161773#discussion_r820134708
        zenKernels = callPackage ./kernel/zen-kernels.nix;

        linux_zen = zenKernels {
          variant = "zen";
          kernelPatches = [
            kernelPatches.bridge_stp_helper
            kernelPatches.request_key_helper
          ];
        };

        linux_lqx = zenKernels {
          variant = "lqx";
          kernelPatches = [
            kernelPatches.bridge_stp_helper
            kernelPatches.request_key_helper
          ];
        };

        # This contains the variants of the XanMod kernel
        xanmodKernels = callPackage ./kernel/xanmod-kernels.nix;

        linux_xanmod = xanmodKernels {
          variant = "lts";
          kernelPatches = [
            kernelPatches.bridge_stp_helper
            kernelPatches.request_key_helper
          ];
        };
        linux_xanmod_stable = xanmodKernels {
          variant = "main";
          kernelPatches = [
            kernelPatches.bridge_stp_helper
            kernelPatches.request_key_helper
          ];
        };
        linux_xanmod_latest = xanmodKernels {
          variant = "main";
          kernelPatches = [
            kernelPatches.bridge_stp_helper
            kernelPatches.request_key_helper
          ];
        };

        linux_6_12_hardened = hardenedKernelFor kernels.linux_6_12 { };

        linux_hardened = hardenedKernelFor packageAliases.linux_default.kernel { };
      }
      // lib.optionalAttrs config.allowAliases {
        linux_libre = throw "linux_libre has been removed due to lack of maintenance";
        linux_latest_libre = throw "linux_latest_libre has been removed due to lack of maintenance";

        linux_4_19 = throw "linux 4.19 was removed because it will reach its end of life within 24.11";
        linux_5_4 = throw "linux 5.4 was removed because it will reach its end of life within 25.11";
        linux_6_9 = throw "linux 6.9 was removed because it has reached its end of life upstream";
        linux_6_10 = throw "linux 6.10 was removed because it has reached its end of life upstream";
        linux_6_11 = throw "linux 6.11 was removed because it has reached its end of life upstream";
        linux_6_13 = throw "linux 6.13 was removed because it has reached its end of life upstream";
        linux_6_14 = throw "linux 6.14 was removed because it has reached its end of life upstream";
        linux_6_15 = throw "linux 6.15 was removed because it has reached its end of life upstream";
        linux_6_16 = throw "linux 6.16 was removed because it has reached its end of life upstream";

        linux_5_10_hardened = throw "linux_hardened on nixpkgs only contains latest stable and latest LTS";
        linux_5_15_hardened = throw "linux_hardened on nixpkgs only contains latest stable and latest LTS";
        linux_6_1_hardened = throw "linux_hardened on nixpkgs only contains latest stable and latest LTS";
        linux_6_6_hardened = throw "linux_hardened on nixpkgs only contains latest stable and latest LTS";

        linux_4_19_hardened = throw "linux 4.19 was removed because it will reach its end of life within 24.11";
        linux_5_4_hardened = throw "linux_5_4_hardened was removed because it was broken";
        linux_6_9_hardened = throw "linux 6.9 was removed because it has reached its end of life upstream";
        linux_6_10_hardened = throw "linux 6.10 was removed because it has reached its end of life upstream";
        linux_6_11_hardened = throw "linux 6.11 was removed because it has reached its end of life upstream";
        linux_6_13_hardened = throw "linux 6.13 was removed because it has reached its end of life upstream";
        linux_6_14_hardened = throw "linux 6.14 was removed because it has reached its end of life upstream";
        linux_6_15_hardened = throw "linux 6.15 was removed because it has reached its end of life upstream";

        linux_rt_5_4 = throw "linux_rt 5.4 has been removed because it will reach its end of life within 25.11";

        linux_ham = throw "linux_ham has been removed in favour of the standard kernel packages";
      };
    /*
      Linux kernel modules are inherently tied to a specific kernel.  So
      rather than provide specific instances of those packages for a
      specific kernel, we have a function that builds those packages
      for a specific kernel.  This function can then be called for
      whatever kernel you're using.
    */

    packagesFor =
      kernel_:
      (lib.makeExtensible (
        self:
        with self;
        let
          callPackage = newScope self;
        in
        {
          inherit callPackage;
          kernel = kernel_;
          inherit (kernel) stdenv; # in particular, use the same compiler by default

          # to help determine module compatibility
          inherit (kernel)
            isLTS
            isZen
            isHardened
            isLibre
            ;
          inherit (kernel) kernelOlder kernelAtLeast;
          kernelModuleMakeFlags = self.kernel.commonMakeFlags ++ [
            "KBUILD_OUTPUT=${kernel.dev}/lib/modules/${kernel.modDirVersion}/build"
          ];
          # Obsolete aliases (these packages do not depend on the kernel).
          inherit (pkgs) odp-dpdk pktgen; # added 2018-05
          inherit (pkgs) bcc bpftrace; # added 2021-12
          inherit (pkgs) oci-seccomp-bpf-hook; # added 2022-11
          inherit (pkgs) dpdk; # added 2024-03

          acer-wmi-battery = callPackage ./acer-wmi-battery { };

          acpi_call = callPackage ./acpi-call { };

          ajantv2 = callPackage ./ajantv2 { };

          akvcam = callPackage ./akvcam { };

          amdgpu-i2c = callPackage ./amdgpu-i2c { };

          amneziawg = callPackage ./amneziawg { };

          apfs = callPackage ./apfs { };

          ax99100 = callPackage ./ax99100 { };

          batman_adv = callPackage ./batman-adv { };

          bbswitch = callPackage ./bbswitch { };

          # NOTE: The bcachefs module is called this way to facilitate
          # easy overriding, as it is expected many users will want to
          # pull from the upstream git repo, which may include
          # unreleased changes to the module build process.
          bcachefs = callPackage pkgs.bcachefs-tools.kernelModule { };

          ch9344 = callPackage ./ch9344 { };

          chipsec = callPackage ../tools/security/chipsec {
            inherit kernel;
            withDriver = true;
          };

          cryptodev = callPackage ./cryptodev { };

          cpupower = callPackage ./cpupower { };

          ddcci-driver = callPackage ./ddcci { };

          dddvb = callPackage ./dddvb { };

          decklink = callPackage ./decklink { };

          digimend = callPackage ./digimend { };

          dpdk-kmods = callPackage ./dpdk-kmods { };

          ecapture = callPackage ../by-name/ec/ecapture/package.nix {
            withNonBTF = true;
            inherit kernel;
          };

          evdi = callPackage ./evdi { };

          fanout = callPackage ./fanout { };

          framework-laptop-kmod = callPackage ./framework-laptop-kmod { };

          fwts-efi-runtime = callPackage ./fwts/module.nix { };

          gasket = callPackage ./gasket { };

          gcadapter-oc-kmod = callPackage ./gcadapter-oc-kmod { };

          hyperv-daemons = callPackage ./hyperv-daemons { };

          e1000e = if lib.versionOlder kernel.version "4.10" then callPackage ./e1000e { } else null;

          iio-utils = if lib.versionAtLeast kernel.version "4.1" then callPackage ./iio-utils { } else null;

          intel-speed-select =
            if lib.versionAtLeast kernel.version "5.3" then callPackage ./intel-speed-select { } else null;

          ipu6-drivers = callPackage ./ipu6-drivers { };

          ivsc-driver = callPackage ./ivsc-driver { };

          ixgbevf = callPackage ./ixgbevf { };

          it87 = callPackage ./it87 { };

          asus-ec-sensors = callPackage ./asus-ec-sensors { };

          ena = callPackage ./ena { };

          lenovo-legion-module = callPackage ./lenovo-legion { };

          linux-gpib = callPackage ../applications/science/electronics/linux-gpib/kernel.nix { };

          liquidtux = callPackage ./liquidtux { };

          lkrg = callPackage ./lkrg { };

          v4l2loopback = callPackage ./v4l2loopback { };

          lttng-modules = callPackage ./lttng-modules { };

          mstflint_access = callPackage ./mstflint_access { };

          broadcom_sta = callPackage ./broadcom-sta { };

          tbs = callPackage ./tbs { };

          mbp2018-bridge-drv = callPackage ./mbp-modules/mbp2018-bridge-drv { };

          nct6687d = callPackage ./nct6687d { };

          new-lg4ff = callPackage ./new-lg4ff { };

          zenergy = callPackage ./zenergy { };

          nvidiabl = callPackage ./nvidiabl { };

          nvidiaPackages = dontRecurseIntoAttrs (lib.makeExtensible (_: callPackage ./nvidia-x11 { }));

          nvidia_x11 = nvidiaPackages.stable;
          nvidia_x11_beta = nvidiaPackages.beta;
          nvidia_x11_latest = nvidiaPackages.latest;
          nvidia_x11_legacy340 = nvidiaPackages.legacy_340;
          nvidia_x11_legacy390 = nvidiaPackages.legacy_390;
          nvidia_x11_legacy470 = nvidiaPackages.legacy_470;
          nvidia_x11_legacy535 = nvidiaPackages.legacy_535;
          nvidia_x11_production = nvidiaPackages.production;
          nvidia_x11_vulkan_beta = nvidiaPackages.vulkan_beta;
          nvidia_dc = nvidiaPackages.dc;
          nvidia_dc_535 = nvidiaPackages.dc_535;
          nvidia_dc_565 = nvidiaPackages.dc_565;

          # this is not a replacement for nvidia_x11*
          # only the opensource kernel driver exposed for hydra to build
          nvidia_x11_beta_open = nvidiaPackages.beta.open;
          nvidia_x11_latest_open = nvidiaPackages.latest.open;
          nvidia_x11_production_open = nvidiaPackages.production.open;
          nvidia_x11_stable_open = nvidiaPackages.stable.open;
          nvidia_x11_vulkan_beta_open = nvidiaPackages.vulkan_beta.open;

          nxp-pn5xx = callPackage ./nxp-pn5xx { };

          openrazer = callPackage ./openrazer/driver.nix { };

          ply = callPackage ./ply { };

          r8125 = callPackage ./r8125 { };

          r8168 = callPackage ./r8168 { };

          rtl8188eus-aircrack = callPackage ./rtl8188eus-aircrack { };

          rtl8192eu = callPackage ./rtl8192eu { };

          rtl8189es = callPackage ./rtl8189es { };

          rtl8189fs = callPackage ./rtl8189fs { };

          rtl8723ds = callPackage ./rtl8723ds { };

          rtl8812au = callPackage ./rtl8812au { };

          rtl8814au = callPackage ./rtl8814au { };

          rtl8852au = callPackage ./rtl8852au { };

          rtl8852bu = callPackage ./rtl8852bu { };

          rtl88xxau-aircrack = callPackage ./rtl88xxau-aircrack { };

          rtl8821au = callPackage ./rtl8821au { };

          rtl8821ce = callPackage ./rtl8821ce { };

          rtl88x2bu = callPackage ./rtl88x2bu { };

          rtl8821cu = callPackage ./rtl8821cu { };

          rtw88 = callPackage ./rtw88 { };

          rtw89 = if lib.versionOlder kernel.version "5.16" then callPackage ./rtw89 { } else null;

          openafs_1_8 = callPackage ../servers/openafs/1.8/module.nix { };
          # Current stable release; don't backport release updates!
          openafs = openafs_1_8;

          opensnitch-ebpf =
            if lib.versionAtLeast kernel.version "5.10" then callPackage ./opensnitch-ebpf { } else null;

          facetimehd = callPackage ./facetimehd { };

          rust-out-of-tree-module =
            if lib.versionAtLeast kernel.version "6.7" then callPackage ./rust-out-of-tree-module { } else null;

          tuxedo-drivers =
            if lib.versionAtLeast kernel.version "4.14" then callPackage ./tuxedo-drivers { } else null;

          jool = callPackage ./jool { };

          kvmfr = callPackage ./kvmfr { };

          mba6x_bl = callPackage ./mba6x_bl { };

          mdio-netlink = callPackage ./mdio-netlink { };

          mwprocapture = callPackage ./mwprocapture { };

          mxu11x0 = callPackage ./mxu11x0 { };

          morse-driver = callPackage ./morse-driver { };

          # compiles but has to be integrated into the kernel somehow
          # Let's have it uncommented and finish it..
          ndiswrapper = callPackage ./ndiswrapper { };

          netatop = callPackage ./netatop { };

          isgx = callPackage ./isgx { };

          rr-zen_workaround = callPackage ../development/tools/analysis/rr/zen_workaround.nix { };

          sheep-net = callPackage ./sheep-net { };

          shufflecake = callPackage ./shufflecake { };

          sysdig = callPackage ./sysdig { };

          systemtap = callPackage ../development/tools/profiling/systemtap { };

          system76 = callPackage ./system76 { };

          system76-acpi = callPackage ./system76-acpi { };

          system76-io = callPackage ./system76-io { };

          tmon = callPackage ./tmon { };

          tp_smapi = callPackage ./tp_smapi { };

          tt-kmd = callPackage ./tt-kmd { };

          turbostat = callPackage ./turbostat { };

          corefreq = callPackage ./corefreq { };

          trelay = callPackage ./trelay { };

          universal-pidff = callPackage ./universal-pidff { };

          usbip = callPackage ./usbip { };

          v86d = callPackage ./v86d { };

          veikk-linux-driver = callPackage ./veikk-linux-driver { };
          vendor-reset = callPackage ./vendor-reset { };

          vhba = callPackage ../applications/emulators/cdemu/vhba.nix { };

          virtio_vmmci = callPackage ./virtio_vmmci { };

          virtualbox = callPackage ./virtualbox {
            virtualbox = pkgs.virtualboxHardened;
          };

          virtualboxGuestAdditions =
            callPackage ../applications/virtualization/virtualbox/guest-additions
              { };

          mm-tools = callPackage ./mm-tools { };

          vmm_clock = callPackage ./vmm_clock { };

          vmware = callPackage ./vmware { };

          wireguard = if lib.versionOlder kernel.version "5.6" then callPackage ./wireguard { } else null;

          x86_energy_perf_policy = callPackage ./x86_energy_perf_policy { };

          xone = if lib.versionAtLeast kernel.version "5.4" then callPackage ./xone { } else null;

          xpadneo = callPackage ./xpadneo { };

          yt6801 = callPackage ./yt6801 { };

          ithc = callPackage ./ithc { };

          ryzen-smu = callPackage ./ryzen-smu { };

          zenpower = callPackage ./zenpower { };

          zfs_2_3 = callPackage ./zfs/2_3.nix {
            configFile = "kernel";
            inherit pkgs kernel;
          };
          zfs_2_4 = callPackage ./zfs/2_4.nix {
            configFile = "kernel";
            inherit pkgs kernel;
          };
          zfs_unstable = callPackage ./zfs/unstable.nix {
            configFile = "kernel";
            inherit pkgs kernel;
          };

          can-isotp = callPackage ./can-isotp { };

          qc71_laptop = callPackage ./qc71_laptop { };

          hid-ite8291r3 = callPackage ./hid-ite8291r3 { };

          hid-t150 = callPackage ./hid-t150 { };

          hid-tmff2 = callPackage ./hid-tmff2 { };

          hpuefi-mod = callPackage ./hpuefi-mod { };

          drbd = callPackage ./drbd/driver.nix { };

          nullfs = callPackage ./nullfs { };

          msi-ec = callPackage ./msi-ec { };

          tsme-test = callPackage ./tsme-test { };

          xpad-noone = callPackage ./xpad-noone { };

        }
        // lib.optionalAttrs config.allowAliases {
          zfs = throw "linuxPackages.zfs has been removed, use zfs_* instead, or linuxPackages.\${pkgs.zfs.kernelModuleAttribute}"; # added 2025-01-23
          zfs_2_1 = throw "zfs_2_1 has been removed"; # added 2024-12-25;
          ati_drivers_x11 = throw "ati drivers are no longer supported by any kernel >=4.1"; # added 2021-05-18;
          deepin-anything-module = throw "the Deepin desktop environment and associated tools have been removed from nixpkgs due to lack of maintenance";
          exfat-nofuse = throw "exfat-nofuse has been removed, all kernels > 5.8 come with built-in exfat support"; # added 2025-10-07
          hid-nintendo = throw "hid-nintendo was added in mainline kernel version 5.16"; # Added 2023-07-30
          sch_cake = throw "sch_cake was added in mainline kernel version 4.19"; # Added 2023-06-14
          rtl8723bs = throw "rtl8723bs was added in mainline kernel version 4.12"; # Added 2023-06-14
          vm-tools = self.mm-tools;
          xmm7360-pci = throw "Support for the XMM7360 WWAN card was added to the iosm kmod in mainline kernel version 5.18";
          amdgpu-pro = throw "amdgpu-pro was removed due to lack of maintenance"; # Added 2024-06-16
          kvdo = throw "kvdo was removed, because it was added to mainline in kernel version 6.9"; # Added 2024-07-08
          perf = lib.warnOnInstantiate "linuxPackages.perf is now perf" pkgs.perf; # Added 2025-08-28
          system76-power = lib.warnOnInstantiate "kernelPackages.system76-power is now pkgs.system76-power" pkgs.system76-power; # Added 2024-10-16
          system76-scheduler = lib.warnOnInstantiate "kernelPackages.system76-scheduler is now pkgs.system76-scheduler" pkgs.system76-scheduler; # Added 2024-10-16
          tuxedo-keyboard = self.tuxedo-drivers; # Added 2024-09-28
          phc-intel = throw "phc-intel drivers are no longer supported by any kernel >=4.17"; # added 2025-07-18
          prl-tools = throw "Parallel Tools no longer provide any kernel module, please use pkgs.prl-tools instead."; # added 2025-10-04
        }
      )).extend
        (lib.fixedPoints.composeManyExtensions kernelPackagesExtensions);

    hardenedPackagesFor = kernel: overrides: packagesFor (hardenedKernelFor kernel overrides);

    vanillaPackages = {
      # recurse to build modules for the kernels
      linux_5_10 = recurseIntoAttrs (packagesFor kernels.linux_5_10);
      linux_5_15 = recurseIntoAttrs (packagesFor kernels.linux_5_15);
      linux_6_1 = recurseIntoAttrs (packagesFor kernels.linux_6_1);
      linux_6_6 = recurseIntoAttrs (packagesFor kernels.linux_6_6);
      linux_6_12 = recurseIntoAttrs (packagesFor kernels.linux_6_12);
      linux_6_17 = recurseIntoAttrs (packagesFor kernels.linux_6_17);
      linux_6_18 = recurseIntoAttrs (packagesFor kernels.linux_6_18);
    }
    // lib.optionalAttrs config.allowAliases {
      linux_4_19 = throw "linux 4.19 was removed because it will reach its end of life within 24.11"; # Added 2024-09-21
      linux_5_4 = throw "linux 5.4 was removed because it will reach its end of life within 25.11"; # Added 2025-10-22
      linux_6_9 = throw "linux 6.9 was removed because it reached its end of life upstream"; # Added 2024-08-02
      linux_6_10 = throw "linux 6.10 was removed because it reached its end of life upstream"; # Added 2024-10-23
      linux_6_11 = throw "linux 6.11 was removed because it reached its end of life upstream"; # Added 2025-03-23
      linux_6_13 = throw "linux 6.13 was removed because it reached its end of life upstream"; # Added 2025-06-22
      linux_6_14 = throw "linux 6.14 was removed because it reached its end of life upstream"; # Added 2025-06-22
      linux_6_15 = throw "linux 6.15 was removed because it reached its end of life upstream"; # Added 2025-08-23
      linux_6_16 = throw "linux 6.16 was removed because it reached its end of life upstream"; # Added 2025-10-22
    };

    rtPackages = {
      # realtime kernel packages
      linux_rt_5_10 = packagesFor kernels.linux_rt_5_10;
      linux_rt_5_15 = packagesFor kernels.linux_rt_5_15;
      linux_rt_6_1 = packagesFor kernels.linux_rt_6_1;
      linux_rt_6_6 = packagesFor kernels.linux_rt_6_6;
    }
    // lib.optionalAttrs config.allowAliases {
      linux_rt_5_4 = throw "linux_rt 5.4 was removed because it will reach its end of life within 25.11"; # Added 2025-10-22
    };

    rpiPackages = {
      linux_rpi1 = packagesFor kernels.linux_rpi1;
      linux_rpi2 = packagesFor kernels.linux_rpi2;
      linux_rpi3 = packagesFor kernels.linux_rpi3;
      linux_rpi4 = packagesFor kernels.linux_rpi4;
    };

    packages = recurseIntoAttrs (
      vanillaPackages
      // rtPackages
      // rpiPackages
      // {

        # Intentionally lacks recurseIntoAttrs, as -rc kernels will quite likely break out-of-tree modules and cause failed Hydra builds.
        linux_testing = packagesFor kernels.linux_testing;

        linux_hardened = recurseIntoAttrs (packagesFor kernels.linux_hardened);

        linux_6_12_hardened = recurseIntoAttrs (packagesFor kernels.linux_6_12_hardened);

        linux_zen = recurseIntoAttrs (packagesFor kernels.linux_zen);
        linux_lqx = recurseIntoAttrs (packagesFor kernels.linux_lqx);
        linux_xanmod = recurseIntoAttrs (packagesFor kernels.linux_xanmod);
        linux_xanmod_stable = recurseIntoAttrs (packagesFor kernels.linux_xanmod_stable);
        linux_xanmod_latest = recurseIntoAttrs (packagesFor kernels.linux_xanmod_latest);
      }
      // lib.optionalAttrs config.allowAliases {
        linux_libre = throw "linux_libre has been removed due to lack of maintenance";
        linux_latest_libre = throw "linux_latest_libre has been removed due to lack of maintenance";

        linux_5_10_hardened = throw "linux_hardened on nixpkgs only contains latest stable and latest LTS";
        linux_5_15_hardened = throw "linux_hardened on nixpkgs only contains latest stable and latest LTS";
        linux_6_1_hardened = throw "linux_hardened on nixpkgs only contains latest stable and latest LTS";
        linux_6_6_hardened = throw "linux_hardened on nixpkgs only contains latest stable and latest LTS";

        linux_4_19_hardened = throw "linux 4.19 was removed because it will reach its end of life within 24.11";
        linux_5_4_hardened = throw "linux_5_4_hardened was removed because it was broken";
        linux_6_9_hardened = throw "linux 6.9 was removed because it has reached its end of life upstream";
        linux_6_10_hardened = throw "linux 6.10 was removed because it has reached its end of life upstream";
        linux_6_11_hardened = throw "linux 6.11 was removed because it has reached its end of life upstream";
        linux_6_13_hardened = throw "linux 6.13 was removed because it has reached its end of life upstream";
        linux_6_14_hardened = throw "linux 6.14 was removed because it has reached its end of life upstream";
        linux_6_15_hardened = throw "linux 6.15 was removed because it has reached its end of life upstream";
        linux_ham = throw "linux_ham has been removed in favour of the standard kernel packages";
      }
    );

    packageAliases = {
      linux_default = packages.linux_6_12;
      # Update this when adding the newest kernel major version!
      linux_latest = packages.linux_6_18;
      linux_rt_default = packages.linux_rt_5_15;
      linux_rt_latest = packages.linux_rt_6_6;
    }
    // lib.optionalAttrs config.allowAliases {
      linux_mptcp = throw "'linux_mptcp' has been moved to https://github.com/teto/mptcp-flake";
    };

    manualConfig = callPackage ./kernel/build.nix { };

    customPackage =
      {
        version,
        src,
        modDirVersion ? lib.versions.pad 3 version,
        configfile,
        allowImportFromDerivation ? false,
      }:
      recurseIntoAttrs (
        packagesFor (manualConfig {
          inherit
            version
            src
            modDirVersion
            configfile
            allowImportFromDerivation
            ;
        })
      );

    # Derive one of the default .config files
    linuxConfig =
      {
        src,
        kernelPatches ? [ ],
        version ? (builtins.parseDrvName src.name).version,
        makeTarget ? "defconfig",
        name ? "kernel.config",
      }:
      stdenvNoCC.mkDerivation {
        inherit name src;
        depsBuildBuild = [
          buildPackages.stdenv.cc
        ]
        ++ lib.optionals (lib.versionAtLeast version "4.16") [
          buildPackages.bison
          buildPackages.flex
        ];
        patches = map (p: p.patch) kernelPatches; # Patches may include new configs.
        postPatch = ''
          patchShebangs scripts/
        '';
        buildPhase = ''
          set -x
          make \
            ARCH=${stdenv.hostPlatform.linuxArch} \
            HOSTCC=${buildPackages.stdenv.cc.targetPrefix}gcc \
            ${makeTarget}
        '';
        installPhase = ''
          cp .config $out
        '';
      };

  }
)
