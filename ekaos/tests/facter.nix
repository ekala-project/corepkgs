# Facter hardware auto-detection tests
# Validates that hardware.facter modules produce correct config
# given various simulated facter reports.
#
# Usage:
#   nix-build ekaos/tests/facter.nix
#   cat result/test-results.txt
{
  pkgs ? import ../../. { },
}:

let
  inherit (pkgs) lib;

  evalEkaos =
    modules:
    (import ../eval-config.nix { inherit lib pkgs; }) {
      modules = [
        {
          serviceManager.systemd.enable = lib.mkDefault true;
          boot.kernelPackages = pkgs.linuxPackages;
          fileSystems."/" = {
            device = "/dev/null";
            fsType = "ext4";
          };
        }
      ]
      ++ modules;
    };

  # ── Simulated facter reports ──────────────────────────────────────

  # Intel ThinkPad laptop: Intel CPU + Intel iGPU + Bluetooth + UEFI
  intelThinkpadReport = builtins.toJSON {
    version = 3;
    system = "x86_64-linux";
    virtualisation = "none";
    uefi = {
      supported = true;
    };
    smbios = {
      system = {
        manufacturer = "LENOVO";
        product_name = "ThinkPad X1 Carbon Gen 11";
        version = "ThinkPad X1 Carbon Gen 11";
      };
      chassis = [
        {
          chassis_type = {
            value = 10;
            name = "Notebook";
          };
          manufacturer = "LENOVO";
        }
      ];
    };
    hardware = {
      cpu = [
        {
          vendor_name = "GenuineIntel";
          model_name = "13th Gen Intel(R) Core(TM) i7-1365U";
          features = [
            "fpu"
            "sse"
            "sse2"
            "avx"
            "avx2"
            "vmx"
            "aes"
          ];
        }
      ];
      graphics_card = [
        {
          vendor = {
            value = 32902;
            name = "Intel Corporation";
          };
          device = {
            value = 42688;
            name = "Raptor Lake-P [Iris Xe Graphics]";
          };
          driver_modules = [ "i915" ];
        }
      ];
      monitor = [
        {
          vendor = {
            name = "AU Optronics";
          };
        }
      ];
      bluetooth = [
        {
          vendor = {
            value = 32902;
            name = "Intel Corporation";
          };
          driver_modules = [ "btusb" ];
        }
      ];
      keyboard = [
        {
          driver_modules = [ "atkbd" ];
        }
      ];
      disk = [
        {
          driver_modules = [ "nvme" ];
        }
      ];
      storage_controller = [
        {
          driver_modules = [ "nvme" ];
        }
      ];
      network_interface = [
        {
          sub_class = {
            name = "WLAN";
          };
          unix_device_names = [ "wlp0s20f3" ];
          driver_modules = [ "iwlwifi" ];
        }
        {
          sub_class = {
            name = "Ethernet";
          };
          unix_device_names = [ "enp0s31f6" ];
          driver_modules = [ "e1000e" ];
        }
      ];
    };
  };

  # AMD desktop: AMD CPU + AMD GPU + no bluetooth + UEFI + not a laptop
  amdDesktopReport = builtins.toJSON {
    version = 3;
    system = "x86_64-linux";
    virtualisation = "none";
    uefi = {
      supported = true;
    };
    smbios = {
      system = {
        manufacturer = "Micro-Star International Co., Ltd.";
        product_name = "MS-7D78";
      };
      chassis = [
        {
          chassis_type = {
            value = 3;
            name = "Desktop";
          };
          manufacturer = "Micro-Star International Co., Ltd.";
        }
      ];
    };
    hardware = {
      cpu = [
        {
          vendor_name = "AuthenticAMD";
          model_name = "AMD Ryzen 9 7950X";
          features = [
            "fpu"
            "sse"
            "sse2"
            "avx"
            "avx2"
            "svm"
            "aes"
          ];
        }
      ];
      graphics_card = [
        {
          vendor = {
            value = 4098;
            name = "Advanced Micro Devices, Inc. [AMD/ATI]";
          };
          device = {
            value = 29823;
            name = "Navi 31 [Radeon RX 7900 XT/7900 XTX]";
          };
          driver_modules = [ "amdgpu" ];
        }
      ];
      monitor = [
        {
          vendor = {
            name = "Dell";
          };
        }
      ];
      keyboard = [
        {
          driver_modules = [ "usbhid" ];
        }
      ];
      disk = [
        {
          driver_modules = [ "nvme" ];
        }
      ];
      storage_controller = [
        {
          driver_modules = [ "nvme" ];
        }
      ];
      network_interface = [
        {
          sub_class = {
            name = "Ethernet";
          };
          unix_device_names = [ "enp6s0" ];
          driver_modules = [ "r8169" ];
        }
      ];
    };
  };

  # QEMU virtual machine: no UEFI, QEMU virt, VirtIO devices
  qemuVmReport = builtins.toJSON {
    version = 3;
    system = "x86_64-linux";
    virtualisation = "kvm";
    uefi = {
      supported = false;
    };
    smbios = { };
    hardware = {
      cpu = [
        {
          vendor_name = "GenuineIntel";
          model_name = "QEMU Virtual CPU";
          features = [
            "fpu"
            "sse"
            "sse2"
            "vmx"
          ];
        }
      ];
      graphics_card = [
        {
          vendor = {
            value = 6900;
            name = "Red Hat, Inc.";
          };
          device = {
            value = 4146;
            name = "Virtio 1.0 GPU";
          };
          driver_modules = [ "virtio_gpu" ];
        }
      ];
      keyboard = [
        {
          driver_modules = [ "atkbd" ];
        }
      ];
      disk = [
        {
          driver_modules = [ "virtio_blk" ];
        }
      ];
      storage_controller = [ ];
      network_interface = [
        {
          sub_class = {
            name = "Ethernet";
          };
          unix_device_names = [ "ens3" ];
          driver_modules = [ "virtio_net" ];
        }
      ];
      scsi = [
        {
          vendor = {
            value = 6900;
          };
          device = {
            value = 4100;
          };
        }
      ];
    };
  };

  # NVIDIA hybrid laptop: Intel CPU + NVIDIA dGPU
  nvidiaLaptopReport = builtins.toJSON {
    version = 3;
    system = "x86_64-linux";
    virtualisation = "none";
    uefi = {
      supported = true;
    };
    smbios = {
      system = {
        manufacturer = "Dell Inc.";
        product_name = "XPS 15 9520";
      };
      chassis = [
        {
          chassis_type = {
            value = 9;
            name = "Laptop";
          };
        }
      ];
    };
    hardware = {
      cpu = [
        {
          vendor_name = "GenuineIntel";
          model_name = "12th Gen Intel(R) Core(TM) i7-12700H";
          features = [
            "fpu"
            "sse"
            "avx2"
            "vmx"
          ];
        }
      ];
      graphics_card = [
        {
          vendor = {
            value = 32902;
            name = "Intel Corporation";
          };
          device = {
            value = 18048;
            name = "Alder Lake-P GT2 [Iris Xe Graphics]";
          };
          driver_modules = [ "i915" ];
        }
        {
          vendor = {
            value = 4318;
            name = "NVIDIA Corporation";
          };
          device = {
            value = 9573;
            name = "GA107M [GeForce RTX 3050 Mobile]";
          };
          driver_modules = [ "nvidia" ];
        }
      ];
      monitor = [
        {
          vendor = {
            name = "Sharp";
          };
        }
      ];
      bluetooth = [
        {
          vendor = {
            value = 32902;
          };
          driver_modules = [ "btusb" ];
        }
      ];
      keyboard = [
        {
          driver_modules = [ "atkbd" ];
        }
      ];
      disk = [
        {
          driver_modules = [ "nvme" ];
        }
      ];
      storage_controller = [ ];
      network_interface = [
        {
          sub_class = {
            name = "WLAN";
          };
          unix_device_names = [ "wlp0s20f3" ];
          driver_modules = [ "iwlwifi" ];
        }
      ];
    };
  };

  # ── Evaluations ───────────────────────────────────────────────────

  mkReportFile = name: json: pkgs.writeText "${name}-facter.json" json;

  intelThinkpad = evalEkaos [
    {
      hardware.facter.reportPath = mkReportFile "intel-thinkpad" intelThinkpadReport;
    }
  ];

  amdDesktop = evalEkaos [
    {
      hardware.facter.reportPath = mkReportFile "amd-desktop" amdDesktopReport;
    }
  ];

  qemuVm = evalEkaos [
    {
      hardware.facter.reportPath = mkReportFile "qemu-vm" qemuVmReport;
    }
  ];

  nvidiaLaptop = evalEkaos [
    {
      hardware.facter.reportPath = mkReportFile "nvidia-laptop" nvidiaLaptopReport;
    }
  ];

  # Disabled facter (no report) — baseline
  noFacter = evalEkaos [ { } ];

  # ── Helpers ───────────────────────────────────────────────────────

  boolToStr = b: if b then "true" else "false";
  hasParam = param: params: builtins.elem param params;

in
pkgs.runCommand "facter-tests"
  {
    # Force evaluation of all configs at build time
    intelThinkpadFacterEnabled = boolToStr intelThinkpad.config.hardware.facter.enable;
    intelCpuDetected = boolToStr intelThinkpad.config.hardware.facter.detected.cpu.intel.enable;
    intelGpuDetected = boolToStr intelThinkpad.config.hardware.facter.detected.gpu.intel.enable;
    intelMicrocode = boolToStr intelThinkpad.config.hardware.cpu.intel.updateMicrocode;
    intelGraphicsEnabled = boolToStr intelThinkpad.config.hardware.graphics.enable;
    intelBluetoothEnabled = boolToStr intelThinkpad.config.hardware.bluetooth.enable;
    intelLaptopDetected = boolToStr intelThinkpad.config.hardware.facter.detected.laptop.enable;
    intelTrackpointDetected = boolToStr intelThinkpad.config.hardware.facter.detected.trackpoint.enable;
    intelTrackpointEnabled = boolToStr intelThinkpad.config.hardware.trackpoint.enable;
    intelThermaldEnabled = boolToStr intelThinkpad.config.services.thermald.enable;
    intelFwupdEnabled = boolToStr intelThinkpad.config.services.fwupd.enable;
    intelCpuFreqGov = intelThinkpad.config.power.cpuFreqGovernor;
    intelPowertopEnabled = boolToStr intelThinkpad.config.power.powertop.enable;
    intelKernelModules = builtins.toJSON intelThinkpad.config.boot.initrd.kernelModules;
    intelKernelParams = builtins.toJSON intelThinkpad.config.boot.kernelParams;
    intelBootKvmModules = builtins.toJSON intelThinkpad.config.boot.kernelModules;
    intelUefiDetected = boolToStr intelThinkpad.config.hardware.facter.detected.uefi.supported;
    intelBaremetal = boolToStr intelThinkpad.config.hardware.facter.detected.virtualisation.none.enable;
    intelKsmEnabled = boolToStr intelThinkpad.config.hardware.ksm.enable;

    amdCpuDetected = boolToStr amdDesktop.config.hardware.facter.detected.cpu.amd.enable;
    amdGpuDetected = boolToStr amdDesktop.config.hardware.facter.detected.gpu.amd.enable;
    amdMicrocode = boolToStr amdDesktop.config.hardware.cpu.amd.updateMicrocode;
    amdGraphicsEnabled = boolToStr amdDesktop.config.hardware.graphics.enable;
    amdGraphics32Bit = boolToStr amdDesktop.config.hardware.graphics.enable32Bit;
    amdLaptopDetected = boolToStr amdDesktop.config.hardware.facter.detected.laptop.enable;
    amdTrackpointDetected = boolToStr amdDesktop.config.hardware.facter.detected.trackpoint.enable;
    amdBluetoothStackEnabled = boolToStr amdDesktop.config.hardware.facter.detected.bluetooth.stack.enable;
    amdKernelModules = builtins.toJSON amdDesktop.config.boot.initrd.kernelModules;
    amdKernelParams = builtins.toJSON amdDesktop.config.boot.kernelParams;
    amdFwupdEnabled = boolToStr amdDesktop.config.services.fwupd.enable;
    amdThermaldEnabled = boolToStr amdDesktop.config.services.thermald.enable;
    amdKsmEnabled = boolToStr amdDesktop.config.hardware.ksm.enable;

    vmFacterEnabled = boolToStr qemuVm.config.hardware.facter.enable;
    vmQemuDetected = boolToStr qemuVm.config.hardware.facter.detected.virtualisation.qemu.enable;
    vmBaremetal = boolToStr qemuVm.config.hardware.facter.detected.virtualisation.none.enable;
    vmRedistribFw = boolToStr qemuVm.config.hardware.enableRedistributableFirmware;
    vmBluetoothStackEnabled = boolToStr qemuVm.config.hardware.facter.detected.bluetooth.stack.enable;
    vmLaptopDetected = boolToStr qemuVm.config.hardware.facter.detected.laptop.enable;
    vmThermaldEnabled = boolToStr qemuVm.config.services.thermald.enable;
    vmFwupdEnabled = boolToStr qemuVm.config.services.fwupd.enable;
    vmKsmEnabled = boolToStr qemuVm.config.hardware.ksm.enable;
    vmVirtioScsi = boolToStr qemuVm.config.hardware.facter.detected.virtualisation.virtio_scsi.enable;
    vmKernelModules = builtins.toJSON qemuVm.config.boot.initrd.kernelModules;
    vmAvailKernelModules = builtins.toJSON qemuVm.config.boot.initrd.availableKernelModules;

    nvGpuIntelDetected = boolToStr nvidiaLaptop.config.hardware.facter.detected.gpu.intel.enable;
    nvGpuNvidiaDetected = boolToStr nvidiaLaptop.config.hardware.facter.detected.gpu.nvidia.enable;
    nvLaptopDetected = boolToStr nvidiaLaptop.config.hardware.facter.detected.laptop.enable;
    nvKernelParams = builtins.toJSON nvidiaLaptop.config.boot.kernelParams;
    nvKernelModules = builtins.toJSON nvidiaLaptop.config.boot.initrd.kernelModules;
    nvTrackpointDetected = boolToStr nvidiaLaptop.config.hardware.facter.detected.trackpoint.enable;

    noFacterEnabled = boolToStr noFacter.config.hardware.facter.enable;
  }
  ''
    mkdir -p $out
    results=$out/test-results.txt

    pass=0
    fail=0

    assert_eq() {
      local name="$1" actual="$2" expected="$3"
      if [ "$actual" = "$expected" ]; then
        echo "PASS: $name" >> "$results"
        pass=$((pass + 1))
      else
        echo "FAIL: $name (expected '$expected', got '$actual')" >> "$results"
        fail=$((fail + 1))
      fi
    }

    assert_contains() {
      local name="$1" haystack="$2" needle="$3"
      if echo "$haystack" | grep -q "$needle"; then
        echo "PASS: $name" >> "$results"
        pass=$((pass + 1))
      else
        echo "FAIL: $name (expected '$needle' in '$haystack')" >> "$results"
        fail=$((fail + 1))
      fi
    }

    assert_not_contains() {
      local name="$1" haystack="$2" needle="$3"
      if ! echo "$haystack" | grep -q "$needle"; then
        echo "PASS: $name" >> "$results"
        pass=$((pass + 1))
      else
        echo "FAIL: $name (should NOT contain '$needle' in '$haystack')" >> "$results"
        fail=$((fail + 1))
      fi
    }

    echo "=== ekaos hardware.facter tests ===" > "$results"
    echo "" >> "$results"

    # ── Intel ThinkPad laptop ──────────────────────────────────────

    echo "--- Intel ThinkPad Laptop ---" >> "$results"

    assert_eq "facter enabled with report" "$intelThinkpadFacterEnabled" "true"
    assert_eq "Intel CPU detected" "$intelCpuDetected" "true"
    assert_eq "Intel GPU detected" "$intelGpuDetected" "true"
    assert_eq "Intel microcode enabled" "$intelMicrocode" "true"
    assert_eq "graphics enabled" "$intelGraphicsEnabled" "true"
    assert_eq "bluetooth enabled" "$intelBluetoothEnabled" "true"
    assert_eq "laptop detected (Notebook chassis)" "$intelLaptopDetected" "true"
    assert_eq "TrackPoint detected (ThinkPad)" "$intelTrackpointDetected" "true"
    assert_eq "TrackPoint module enabled" "$intelTrackpointEnabled" "true"
    assert_eq "thermald enabled (Intel bare-metal)" "$intelThermaldEnabled" "true"
    assert_eq "fwupd enabled (UEFI bare-metal)" "$intelFwupdEnabled" "true"
    assert_eq "CPU freq governor is powersave" "$intelCpuFreqGov" "powersave"
    assert_eq "powertop enabled" "$intelPowertopEnabled" "true"
    assert_contains "i915 in initrd modules" "$intelKernelModules" "i915"
    assert_eq "UEFI detected" "$intelUefiDetected" "true"
    assert_eq "bare-metal detected" "$intelBaremetal" "true"
    assert_eq "KSM enabled (bare-metal)" "$intelKsmEnabled" "true"
    assert_contains "kvm-intel loaded" "$intelBootKvmModules" "kvm-intel"

    # ── AMD Desktop ────────────────────────────────────────────────

    echo "" >> "$results"
    echo "--- AMD Desktop ---" >> "$results"

    assert_eq "AMD CPU detected" "$amdCpuDetected" "true"
    assert_eq "AMD GPU detected" "$amdGpuDetected" "true"
    assert_eq "AMD microcode enabled" "$amdMicrocode" "true"
    assert_eq "graphics enabled" "$amdGraphicsEnabled" "true"
    assert_eq "32-bit graphics enabled (AMD)" "$amdGraphics32Bit" "true"
    assert_eq "NOT a laptop (Desktop chassis)" "$amdLaptopDetected" "false"
    assert_eq "no TrackPoint (not ThinkPad)" "$amdTrackpointDetected" "false"
    assert_eq "no bluetooth (none in report)" "$amdBluetoothStackEnabled" "false"
    assert_contains "amdgpu in initrd modules" "$amdKernelModules" "amdgpu"
    assert_contains "amd_pstate=active param" "$amdKernelParams" "amd_pstate=active"
    assert_eq "fwupd enabled (UEFI bare-metal)" "$amdFwupdEnabled" "true"
    assert_eq "thermald NOT enabled (AMD)" "$amdThermaldEnabled" "false"
    assert_eq "KSM enabled (bare-metal)" "$amdKsmEnabled" "true"

    # ── QEMU VM ────────────────────────────────────────────────────

    echo "" >> "$results"
    echo "--- QEMU Virtual Machine ---" >> "$results"

    assert_eq "facter enabled" "$vmFacterEnabled" "true"
    assert_eq "QEMU detected" "$vmQemuDetected" "true"
    assert_eq "NOT bare-metal" "$vmBaremetal" "false"
    assert_eq "no redistributable firmware (VM)" "$vmRedistribFw" "false"
    assert_eq "no bluetooth stack (VM)" "$vmBluetoothStackEnabled" "false"
    assert_eq "NOT a laptop" "$vmLaptopDetected" "false"
    assert_eq "thermald NOT enabled (VM)" "$vmThermaldEnabled" "false"
    assert_eq "fwupd NOT enabled (VM, no UEFI)" "$vmFwupdEnabled" "false"
    assert_eq "KSM NOT enabled (not bare-metal)" "$vmKsmEnabled" "false"
    assert_eq "VirtIO SCSI detected" "$vmVirtioScsi" "true"
    assert_contains "virtio_balloon in initrd" "$vmKernelModules" "virtio_balloon"
    assert_contains "virtio_console in initrd" "$vmKernelModules" "virtio_console"
    assert_contains "virtio_pci available" "$vmAvailKernelModules" "virtio_pci"
    assert_contains "virtio_scsi available" "$vmAvailKernelModules" "virtio_scsi"
    assert_contains "9p available" "$vmAvailKernelModules" "9p"

    # ── NVIDIA Hybrid Laptop ──────────────────────────────────────

    echo "" >> "$results"
    echo "--- NVIDIA Hybrid Laptop ---" >> "$results"

    assert_eq "Intel iGPU detected" "$nvGpuIntelDetected" "true"
    assert_eq "NVIDIA dGPU detected" "$nvGpuNvidiaDetected" "true"
    assert_eq "laptop detected" "$nvLaptopDetected" "true"
    assert_contains "i915 in initrd" "$nvKernelModules" "i915"
    assert_contains "nvidia-drm.modeset=1 param" "$nvKernelParams" "nvidia-drm.modeset=1"
    assert_eq "no TrackPoint (not ThinkPad)" "$nvTrackpointDetected" "false"

    # ── No Facter (baseline) ──────────────────────────────────────

    echo "" >> "$results"
    echo "--- No Facter Report ---" >> "$results"

    assert_eq "facter disabled without report" "$noFacterEnabled" "false"

    # ── Summary ───────────────────────────────────────────────────

    echo "" >> "$results"
    echo "=== SUMMARY: $pass passed, $fail failed ===" >> "$results"

    cat "$results"

    if [ "$fail" -gt 0 ]; then
      touch $out/failure
      exit 1
    else
      touch $out/success
    fi
  ''
