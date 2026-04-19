# Missing Packages for ekaos Boot Support

This document lists packages that are required for creating bootable ekaos systems but may not be present in core-pkgs.

## Critical Packages (Required for Boot)

### 1. systemd
**Status**: Available in nixpkgs (`/home/jon/projects/nixpkgs/pkgs/os-specific/linux/systemd/`)

**Purpose**: Init system (PID 1), service manager, and bootctl for systemd-boot

**Components needed**:
- `/lib/systemd/systemd` - Main init binary (PID 1)
- `bootctl` - Boot loader manager (installs/updates systemd-boot)
- `systemctl` - Service control
- `journalctl` - Log viewer
- systemd unit files and targets

**Version**: 258.2 (based on symlinks in `/nix/store/`)

**Action**: Need to ensure systemd is built and available in core-pkgs, or import from nixpkgs

### 2. Linux Kernel
**Status**: Available in nixpkgs (`pkgs.linuxPackages`, `pkgs.linux`)

**Purpose**: Operating system kernel

**Components needed**:
- Kernel image (`bzImage` for x86_64, `Image` for ARM)
- Kernel modules (drivers)
- Kernel headers (for building modules)

**Variants**:
- `pkgs.linux` - Default stable kernel
- `pkgs.linuxPackages_latest` - Latest kernel
- `pkgs.linuxPackages_hardened` - Hardened kernel

**Action**: Import kernel packages from nixpkgs or build minimal kernel

### 3. util-linux
**Status**: Likely available in nixpkgs

**Purpose**: Essential system utilities

**Components needed**:
- `mount` / `umount` - Filesystem mounting
- `findmnt` - Find mount points
- `mountpoint` - Check if path is mount point
- `swapon` / `swapoff` - Swap management

**Action**: Verify availability, import if needed

### 4. coreutils
**Status**: Likely available in core-pkgs or nixpkgs

**Purpose**: Basic file and text utilities

**Components needed**:
- `mkdir`, `chmod`, `chown` - File operations
- `ln`, `cp`, `mv` - File manipulation
- `cat`, `echo` - Text operations
- `dirname`, `basename` - Path manipulation

**Action**: Verify availability

## Boot Loader Packages (systemd-boot)

### 5. Python 3
**Status**: Likely available in nixpkgs

**Purpose**: Running systemd-boot-builder.py script

**Components needed**:
- Python 3 interpreter
- Standard library modules: `argparse`, `os`, `subprocess`, `json`, `shutil`

**Action**: Import from nixpkgs if not in core-pkgs

### 6. jq
**Status**: Likely available in nixpkgs

**Purpose**: JSON processing for bootspec (boot.json) generation

**Usage**:
- Manipulating bootspec JSON
- Adding toplevel and init paths
- Merging bootspec extensions

**Action**: Import from nixpkgs if not in core-pkgs

## Optional But Recommended Packages

### 7. nix
**Status**: Available in nixpkgs

**Purpose**: Package manager (used by systemd-boot-builder.py for generation management)

**Components used**:
- `nix-env` - Managing generations (optional)

**Note**: May not be strictly necessary for boot, but used by NixOS boot loader scripts

**Action**: Consider importing for generation management

### 8. bash / runtimeShell
**Status**: Likely available

**Purpose**: Shell for init scripts and activation scripts

**Action**: Verify availability

## Build-Time Dependencies

### 9. substituteAll / stdenvNoCC
**Status**: Should be in stdenv

**Purpose**: Building derivations and substituting variables in scripts

**Action**: Verify stdenv functionality

## Summary of Actions

### Immediate Requirements
1. **systemd** - Critical for boot, need full package
2. **Linux kernel** - Essential, import from nixpkgs
3. **util-linux** - Required for mounting, verify availability
4. **coreutils** - Basic utilities, verify availability
5. **Python 3** - For boot builder script
6. **jq** - For bootspec generation

### Nice to Have
7. **nix** - For generation management (can defer)
8. **bash** - For shell scripts (probably available)

## Integration Strategy

### Option 1: Import from nixpkgs
Add to ekaos module system:
```nix
{ pkgs }:
{
  # Use nixpkgs packages
  systemd.package = pkgs.systemd;
  boot.kernelPackages = pkgs.linuxPackages;
}
```

### Option 2: Build in core-pkgs
If core-pkgs needs to be self-contained:
1. Port systemd build from nixpkgs
2. Port kernel build from nixpkgs
3. Ensure all dependencies are available

### Recommendation
Start with **Option 1** (import from nixpkgs) for faster iteration, then gradually move to Option 2 if self-containment is required.

## Testing Package Availability

To check if a package is available:

```bash
# Check in core-pkgs
nix-build -E 'with import ./. {}; systemd'

# Check in nixpkgs
nix-build '<nixpkgs>' -A systemd

# Check specific package from nixpkgs
nix-build /home/jon/projects/nixpkgs -A systemd
```

## Next Steps

1. Verify which packages are already in core-pkgs
2. Import missing packages from nixpkgs
3. Test that bootable system can be built
4. Document any additional runtime dependencies discovered during testing
