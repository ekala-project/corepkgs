# ekaos - Bootable System Builder

ekaos is a minimal, bootable Linux system builder using Nix. It provides a clean, modular approach to creating bootable systems with systemd.

## Features

- **Minimal boot path**: UEFI → systemd-boot → kernel → stage-2 init → systemd
- **Two-stage boot**: Optional initramfs for LUKS encryption, LVM, custom modules
- **Modular configuration**: NixOS-inspired module system
- **Service management**: Integrates with the ekaos unified service interface (services/)
- **systemd-boot**: Modern UEFI bootloader with automatic boot entry generation
- **Bootspec compliant**: Uses RFC-0125 bootspec (boot.json) for boot configuration
- **Testing framework**: ekaosTest - automated testing with Python test driver (see `lib/testing/README.md`)

## Quick Start

### Build a Minimal System

```bash
# Build the minimal example system
cd /home/jon/projects/core-pkgs
nix-build ekaos -A system

# Result structure:
./result/
├── init                    # Stage-2 init script
├── boot.json              # Bootspec document
├── etc/                   # System configuration
├── sw/                    # System packages
├── systemd/               # Systemd package
├── activate               # Activation script
├── ekaos-version         # Version string
└── extra-dependencies/   # GC roots

# Inspect the boot configuration
cat result/boot.json

# View the init script
cat result/init
```

### Build a Custom Configuration

Create a configuration file:

```nix
# my-system.nix
{ config, lib, pkgs, ... }:

{
  system.ekaos.version = "24.11";
  system.ekaos.label = "my-ekaos-system";

  boot.loader.systemd-boot.enable = true;
  boot.kernelPackages = pkgs.linuxPackages;

  environment.systemPackages = with pkgs; [
    coreutils
    util-linux
    systemd
    vim
    git
  ];
}
```

Build it:

```bash
nix-build ekaos --arg configuration ./my-system.nix -A system
```

## Architecture

```
ekaos/
├── eval-config.nix           # System evaluation entry point
├── default.nix               # Main builder interface
├── modules/
│   ├── module-list.nix       # List of base modules
│   ├── boot/
│   │   ├── kernel.nix        # Kernel configuration
│   │   ├── initrd.nix        # Initramfs (stage-1) configuration
│   │   ├── stage-2.nix       # Stage-2 init script
│   │   └── systemd-boot.nix  # systemd-boot bootloader
│   ├── system/
│   │   ├── toplevel.nix      # System closure builder
│   │   ├── activation.nix    # Activation scripts
│   │   └── etc.nix           # /etc management
│   └── systemd.nix           # Systemd integration
├── lib/
│   ├── systemd-boot-builder.py  # Boot entry generator
│   └── make-initrd.nix       # Initramfs builder
└── examples/
    ├── minimal-system.nix    # Minimal configuration example
    └── initrd-system.nix     # Initramfs example
```

## Boot Process

### Without Initramfs (Direct Boot)

1. **UEFI Firmware** loads systemd-boot from ESP
2. **systemd-boot** reads boot entries from `/boot/loader/entries/`
3. **Kernel** loads with `init=/nix/store/.../init` parameter
4. **Stage-2 Init** (`init` script):
   - Mounts special filesystems (/proc, /sys, /dev, /run)
   - Mounts /nix/store as read-only
   - Runs activation script
   - Records booted system in `/run/booted-system`
   - Execs systemd as PID 1
5. **Systemd** starts services and reaches `multi-user.target`

### With Initramfs (Two-Stage Boot)

1. **UEFI Firmware** loads systemd-boot from ESP
2. **systemd-boot** reads boot entries from `/boot/loader/entries/`
3. **Kernel** loads with initrd and `init=/init` (in initramfs)
4. **Stage-1 Init** (initramfs `/init` script):
   - Mounts essential filesystems (/proc, /sys, /dev, /run)
   - Loads kernel modules for hardware
   - Unlocks LUKS encrypted devices
   - Mounts root filesystem
   - Switches to real root via `switch_root`
5. **Stage-2 Init** (`/init` on real root):
   - Continues with normal activation
   - Mounts /nix/store as read-only
   - Runs activation script
   - Execs systemd as PID 1
6. **Systemd** starts services and reaches `multi-user.target`

## Configuration Options

### Boot Options

```nix
boot.loader.systemd-boot.enable = true;
boot.loader.systemd-boot.timeout = 5;
boot.loader.systemd-boot.editor = true;
boot.loader.systemd-boot.configurationLimit = 20;

boot.kernelPackages = pkgs.linuxPackages;
boot.kernelParams = [ "quiet" "splash" ];
boot.kernelModules = [ "kvm-intel" ];
```

### System Options

```nix
system.ekaos.version = "24.11";
system.ekaos.label = "my-system";

environment.systemPackages = [ pkgs.vim pkgs.git ];
```

### Initramfs (initrd) Options

ekaos supports two-stage boot with initramfs for advanced scenarios:

```nix
boot.initrd = {
  enable = true;  # Enable initramfs (stage-1 boot)

  # Kernel modules to load in stage-1
  availableKernelModules = [
    # SATA controllers
    "ahci" "ata_piix"
    # NVMe
    "nvme"
    # USB
    "xhci_pci" "ehci_pci" "usb_storage" "sd_mod"
    # VirtIO (for VMs)
    "virtio_blk" "virtio_pci"
  ];

  # Additional modules
  kernelModules = [ "ext4" ];

  # Filesystem support
  supportedFilesystems = [ "ext4" "vfat" ];

  # Compression (gzip, xz, zstd, lz4, lzop)
  compressor = "gzip";

  # LUKS encryption support
  luks.devices = {
    root = {
      device = "/dev/vda2";
      name = "cryptroot";
      allowDiscards = true;  # Enable TRIM for SSDs
    };
  };

  # Custom commands during boot
  postDeviceCommands = ''
    echo "Stage-1: Devices initialized"
  '';

  postMountCommands = ''
    echo "Stage-1: Root filesystem mounted"
  '';
};
```

**When to use initramfs:**
- Encrypted root filesystem (LUKS)
- LVM root filesystem
- Software RAID
- Network root filesystem (iSCSI, NFS)
- Non-standard root filesystem types
- Custom kernel module loading

**See `examples/initrd-system.nix` for a complete example.**

### Activation Scripts

```nix
system.activationScripts.mysetup = {
  deps = [ "etc" ];  # Run after /etc setup
  text = ''
    echo "Setting up my component..."
    mkdir -p /var/lib/myservice
  '';
};
```

### /etc Files

```nix
environment.etc."myconfig.conf" = {
  text = ''
    # My configuration
    option = value
  '';
  mode = "0644";
};
```

## Installation (Manual)

**Note**: Automatic installation is not yet implemented. For now, you can manually install to a disk:

1. **Partition and format disk**:
   ```bash
   # Create GPT partition table
   parted /dev/sdX mklabel gpt

   # Create ESP (EFI System Partition)
   parted /dev/sdX mkpart ESP fat32 1MiB 512MiB
   parted /dev/sdX set 1 esp on

   # Create root partition
   parted /dev/sdX mkpart primary ext4 512MiB 100%

   # Format partitions
   mkfs.fat -F 32 /dev/sdX1
   mkfs.ext4 /dev/sdX2
   ```

2. **Mount filesystems**:
   ```bash
   mount /dev/sdX2 /mnt
   mkdir -p /mnt/boot
   mount /dev/sdX1 /mnt/boot
   mkdir -p /mnt/nix
   ```

3. **Copy system closure**:
   ```bash
   # Build system
   nix-build ekaos -A system

   # Copy closure to disk
   nix copy --to /mnt ./result

   # Set up /nix/store
   cp -a /nix/store/* /mnt/nix/store/
   ```

4. **Install bootloader**:
   ```bash
   # Run the boot loader installer
   # (This needs to be run in a chroot or adapted for external installation)
   ./result/bin/install-bootloader ./result
   ```

5. **Reboot into ekaos**

## Testing in QEMU

ekaos includes comprehensive QEMU/VM testing infrastructure for rapid boot testing and validation.

### Quick Test

The fastest way to test boot:

```bash
cd /home/jon/projects/core-pkgs/ekaos
./tests/quick-test.sh
```

This builds and boots the minimal test configuration, runs for 30 seconds to verify boot, then exits.

### Build and Run a VM

**Option 1: Using the wrapper script**

```bash
# Run with default minimal configuration
./lib/run-vm.sh

# Run with custom configuration
./lib/run-vm.sh ./examples/minimal-system.nix

# Run the test configuration
./lib/run-vm.sh ./tests/minimal-boot-test.nix
```

**Option 2: Using nix-build directly**

```bash
# Build VM for the minimal system
nix-build ekaos -A tests.boot.vm

# Run the VM
./result
```

### Build a Disk Image

Create a bootable QCOW2 disk image:

```bash
# Build disk image
nix-build ekaos -A tests.boot.diskImage

# Result structure:
./result/
├── nixos.qcow2      # Bootable disk image
└── efi-vars.fd      # EFI variables

# Boot manually with QEMU
qemu-system-x86_64 \
  -m 2048 \
  -drive if=pflash,format=raw,readonly=on,file=/nix/store/.../OVMF_CODE.fd \
  -drive if=pflash,format=raw,file=./result/efi-vars.fd \
  -drive file=./result/nixos.qcow2,if=virtio \
  -nographic
```

### Enable VM Support in Configuration

Add VM configuration to any ekaos system:

```nix
{ config, pkgs, ... }:

{
  # Your normal configuration
  system.ekaos.label = "my-system";
  boot.loader.systemd-boot.enable = true;

  # Enable VM build
  virtualisation = {
    enable = true;
    memorySize = 2048;      # MB
    cores = 2;
    diskSize = 8192;        # MB
    serialConsole = true;   # Use serial console (headless)
  };
}
```

Then build:

```bash
nix-build -A vm your-config.nix
./result  # Runs the VM
```

### VM Configuration Options

```nix
virtualisation = {
  enable = true;

  # Resources
  memorySize = 2048;        # RAM in MB
  cores = 2;                # CPU cores
  diskSize = 8192;          # Disk size in MB

  # Display
  serialConsole = true;     # Use serial console (headless)
  displayType = "gtk";      # Or "sdl", "vnc" (if serialConsole = false)

  # Network
  enableNetwork = true;     # User-mode networking

  # Custom QEMU options
  qemuOptions = ''
    QEMU_OPTS+=(-cdrom /path/to/cd.iso)
  '';
};
```

### Automated Testing with ekaosTest

ekaos includes **ekaosTest**, a comprehensive testing framework inspired by nixosTest. It provides Python test scripts with high-level primitives for testing boot, services, and system behavior.

**Quick example tests:**

```bash
# Run a simple boot test
nix-build ekaos/tests -A simple

# Run a service management test
nix-build ekaos/tests -A service

# Run a boot process test
nix-build ekaos/tests -A boot-process

# Run all tests
nix-build ekaos/tests -A all
```

**Write your own test:**

```nix
# my-test.nix
{ pkgs, ... }:

{
  name = "my-service-test";

  nodes.machine = { config, pkgs, ... }: {
    boot.kernelPackages = pkgs.linuxPackages;
    virtualisation.enable = true;
  };

  testScript = ''
    machine.start()
    machine.wait_for_unit("multi-user.target")
    machine.wait_for_unit("my-service.service")
    machine.succeed("systemctl status my-service")
    machine.shutdown()
  '';
}
```

**Run it:**

```bash
nix-build -E '(import ./. {}).ekaosTest ./my-test.nix'
```

See **`lib/testing/README.md`** for complete ekaosTest documentation, API reference, and examples.

#### Legacy Boot Test

The original simple boot test is still available:

```bash
# Build and run boot test
nix-build ekaos/tests -A boot-test.test

# Run the test
./result
```

The test:
1. Builds a VM with the test configuration
2. Boots the system
3. Waits 30 seconds
4. Verifies no crashes occurred
5. Reports success/failure

### What to Expect

When the VM boots successfully, you'll see:

```
ekaos stage-2 init starting...
Mounting special filesystems...
Running activation script...
Setting up /etc...
Setting up systemd units...
Activation complete.
Starting systemd...

Welcome to ekaos 24.11!

[  OK  ] Reached target Multi-User System.
[  OK  ] Reached target Graphical Interface.

ekaos-boot-test login:
```

For the test configuration, you'll also see:

```
=========================================
ekaos BOOT TEST SUCCESS!
System booted and systemd started
=========================================
```

### Troubleshooting

**VM fails to build:**
- Check that OVMF package is available: `nix-build '<nixpkgs>' -A OVMF`
- Check that QEMU is available: `nix-build '<nixpkgs>' -A qemu`

**VM boots but hangs:**
- Check kernel parameters include serial console
- Try increasing memory: `virtualisation.memorySize = 4096`

**Bootloader not found:**
- Verify systemd-boot is enabled: `boot.loader.systemd-boot.enable = true`
- Check boot.json was generated: `cat result/boot.json`

**No output on serial console:**
- Ensure kernel params: `boot.kernelParams = [ "console=ttyS0,115200" ]`
- Check VM configuration: `virtualisation.serialConsole = true`

## Current Limitations

- **Manual installation to real hardware**: Automated installer for physical disks not yet implemented
- **systemd-boot only**: GRUB not yet supported
- **Minimal /etc management**: Simple symlink farm, no overlays
- **No networking**: Network configuration not yet implemented
- **No users**: User management not yet implemented
- **Basic VM testing only**: Real hardware boot testing needed

## What Works

✅ **QEMU/VM boot testing** - Full testing infrastructure with automated tests
✅ **systemd-boot bootloader** - Generates boot entries, manages generations
✅ **Bootspec (boot.json)** - RFC-0125 compliant boot configuration
✅ **Initramfs (initrd)** - Two-stage boot with LUKS, LVM, custom modules
✅ **Stage-1 init** - Kernel module loading, device unlocking, root mounting
✅ **Stage-2 init** - Mounts filesystems, runs activation, starts systemd
✅ **Activation framework** - Topologically sorted system setup
✅ **Service management** - Unified interface for systemd services
✅ **Disk image creation** - Automated QCOW2 image generation for VMs

## Next Steps (Future Work)

1. **Real hardware testing**: Test boot on physical machines
2. **Automatic installer**: Script for easy installation to physical disks
3. **Network configuration**: Add networking modules (static IP, DHCP, etc.)
4. **User management**: Add user/group management modules
5. **More services**: Add essential system services (sshd, cron, etc.)
6. **GRUB support**: Add alternative bootloader for legacy BIOS
7. **Filesystem management**: Better /etc handling, fstab generation, ZFS/Btrfs support
8. **Network root filesystem**: Add iSCSI/NFS support to initramfs

## Dependencies

See `missing-packages.md` for detailed information about required packages.

**Critical dependencies**:
- systemd
- Linux kernel
- util-linux
- coreutils
- Python 3
- jq

Most of these should be available from nixpkgs and can be imported as needed.

## Related Projects

- **services/**: ekaos unified service management (systemd, launchd, runit, rc.d)
- **NixOS**: Inspiration for module system and boot process
- **Bootspec RFC-0125**: Standard for boot configuration

## License

(Add license information here)
