# Adios port of ekaos/modules/installer/iso-image.nix.
# TODO(adios-cutover) notes below mark semantics changed in translation.
{ types, pkgs, ... }:

{
  options = {
    enable = {
      type = types.bool;
      default = false;
      description = "Whether to enable ISO image generation for this system.";
    };

    volumeID = {
      type = types.string;
      default = "EKAOS";
      description = ''
        ISO 9660 volume identifier. Used by the initrd to find and mount
        the ISO filesystem during boot. Maximum 32 characters.
      '';
    };

    edition = {
      type = types.string;
      default = "";
      description = "Edition string included in the ISO file name.";
    };

    squashfsCompression = {
      type = types.nullOr types.string;
      default = "zstd -Xcompression-level 6";
      description = ''
        Compression settings for the squashfs nix store image.
        Set to null to disable compression.
      '';
    };

    compressImage = {
      type = types.bool;
      default = false;
      description = "Whether to compress the final ISO image with zstd.";
    };

    bootTimeout = {
      type = types.int;
      default = 10;
      description = "Boot menu timeout in seconds.";
    };

    bootMenuLabel = {
      type = types.string;
      # TODO(adios-cutover): default references config.system.ekaos.version
      # (defined in ekaos/modules/system/toplevel.nix); flat leaf name pending
      # the system/toplevel port — full legacy path used below.
      defaultFunc = { inputs, ... }: "EkaOS ${inputs.sys.ekaos.version}";
      description = "Label shown in the boot menu.";
    };

    contents = {
      type = types.listOf types.attrs;
      # TODO(adios-cutover): submodule validation lost. Each entry is a raw
      # attrset with source (path, required) and target (string, required).
      default = [ ];
      description = "Additional files and directories to include on the ISO.";
    };

    storeContents = {
      type = types.listOf types.derivation;
      default = [ ];
      description = ''
        Additional store paths to include in the squashfs nix store image.
        The system closure is always included.
      '';
    };

    # Legacy internal option system.build.isoImage is folded into impl below
    # (it is a computed output, not an input).
  };

  inputs = {
    kernel.from = { root }: root.boot.kernel;
    initrd.from = { root }: root.boot.initrd;
    # TODO(adios-cutover): impl-body references to
    # inputs.sys.system.build.toplevel / inputs.initrd.system.build.initialRamdisk
    # (legacy internal options) cannot resolve via adios inputs, which only see
    # sibling OPTIONS, not impl outputs. They evaluate only when enable=true;
    # enabling iso-image needs out-of-band wiring of those build outputs.
    sys.from = { root }: root.system.toplevel;
    nixCfg.from = { root }: root.config.nix-daemon;
  };

  assertions = [
    {
      # Legacy asserted this only when enabled; the condition is encoded here.
      verify = { options, ... }: !options.enable || builtins.stringLength options.volumeID <= 32;
      explain =
        { options, ... }:
        "isoImage.volumeID must be at most 32 characters (got ${toString (builtins.stringLength options.volumeID)}).";
    }
  ];

  impl =
    { options, inputs }:
    if !options.enable then
      { }
    else
      let
        # Smallest local reimplementation (lib.toUpper has no builtin
        # equivalent); only used for the EFI fallback binary name.
        toUpper =
          s:
          builtins.replaceStrings
            [
              "a"
              "b"
              "c"
              "d"
              "e"
              "f"
              "g"
              "h"
              "i"
              "j"
              "k"
              "l"
              "m"
              "n"
              "o"
              "p"
              "q"
              "r"
              "s"
              "t"
              "u"
              "v"
              "w"
              "x"
              "y"
              "z"
            ]
            [
              "A"
              "B"
              "C"
              "D"
              "E"
              "F"
              "G"
              "H"
              "I"
              "J"
              "K"
              "L"
              "M"
              "N"
              "O"
              "P"
              "Q"
              "R"
              "S"
              "T"
              "U"
              "V"
              "W"
              "X"
              "Y"
              "Z"
            ]
            s;
        kernelPath = "${inputs.kernel.kernelPackages.kernel}/${inputs.kernel.kernelFile}";
        # TODO(adios-cutover): initialRamdisk is an impl-computed output of the
        # boot/initrd port (legacy internal option system.build.initialRamdisk
        # folded into its impl); confirm the tree exposes impl values here.
        initrdPath = "${inputs.initrd.system.build.initialRamdisk}/initrd";

        loaderConf = pkgs.writeText "loader.conf" ''
          timeout ${toString options.bootTimeout}
          default ekaos.conf
          editor no
        '';

        bootEntry = pkgs.writeText "ekaos.conf" ''
          title   ${options.bootMenuLabel}
          linux   /EFI/ekaos/vmlinuz
          initrd  /EFI/ekaos/initrd
          options init=${inputs.sys.system.build.toplevel}/init ${toString inputs.kernel.kernelParams}
        '';

        efiDir = pkgs.runCommand "efi-directory" { } ''
          mkdir -p $out/EFI/BOOT $out/EFI/ekaos $out/loader/entries

          # Copy the systemd-boot EFI binary
          bootBinary="${inputs.sys.systemd.package}/lib/systemd/boot/efi/systemd-boot${pkgs.stdenv.hostPlatform.efiArch}.efi"

          if [ -f "$bootBinary" ]; then
            cp "$bootBinary" "$out/EFI/BOOT/BOOT${toUpper pkgs.stdenv.hostPlatform.efiArch}.EFI"
          else
            echo "error: systemd-boot EFI binary not found at $bootBinary" >&2
            exit 1
          fi

          # Copy kernel and initrd
          cp ${kernelPath} $out/EFI/ekaos/vmlinuz
          cp ${initrdPath} $out/EFI/ekaos/initrd

          # Loader configuration
          cp ${loaderConf} $out/loader/loader.conf
          cp ${bootEntry} $out/loader/entries/ekaos.conf
        '';

        efiImg =
          pkgs.runCommand "efi-image"
            {
              nativeBuildInputs = [
                pkgs.dosfstools
                pkgs.mtools
              ];
            }
            ''
              # Copy EFI directory contents
              mkdir ./contents && cd ./contents
              cp -r ${efiDir}/* .

              # Rewrite dates for reproducibility
              find . -exec touch --date=2000-01-01 {} +

              # Calculate image size: 110% of content size, rounded up to 1 MiB blocks
              usage_size=$(du -sb --apparent-size . | cut -f1)
              image_size=$(( (usage_size * 110 / 100 + 1048575) / 1048576 * 1048576 ))
              # Minimum 4 MiB for FAT overhead
              if [ "$image_size" -lt 4194304 ]; then
                image_size=4194304
              fi

              truncate --size=$image_size "$out"
              mkfs.vfat -i 12345678 -n EFIBOOT "$out"

              # Populate the FAT image
              for d in $(find . -type d | sort); do
                mmd -i "$out" "::/$d" 2>/dev/null || true
              done
              for f in $(find . -type f | sort); do
                mcopy -i "$out" "$f" "::/$f"
              done

              # Verify
              fsck.vfat -vn "$out"
            '';

        # Legacy appended the system closure to its own storeContents option;
        # the effective list is computed here.
        storeContents = options.storeContents ++ [ inputs.sys.system.build.toplevel ];

        isoBaseName = "ekaos${
          if options.edition != "" then "-${options.edition}" else ""
        }-${inputs.sys.system.ekaos.version}-${pkgs.stdenv.hostPlatform.system}";
      in
      {
        # Enable initrd for the live boot sequence
        boot.initrd.enable = true;

        # Kernel modules needed for ISO live boot
        boot.initrd.availableKernelModules = [
          "iso9660"
          "sr_mod" # CD/DVD drive
          "uas" # USB attached SCSI
          "usb_storage"
        ];

        boot.initrd.kernelModules = [
          "squashfs"
          "loop"
          "overlay"
        ];

        # Filesystem support in initrd
        boot.initrd.supportedFilesystems = [ "vfat" ];

        # Tell the initrd how to find the root
        boot.kernelParams = [
          "boot.shell_on_fail"
          "root=live:LABEL=${options.volumeID}"
        ];

        # Disable the standard boot loader installer (not needed for ISOs)
        # TODO(adios-cutover): priority lost (was mkForce).
        boot.loader.systemd-boot.enable = false;

        # Extra initrd utilities needed for live boot
        boot.initrd.extraUtilsCommands = ''
          # Copy losetup for loop device management
          copy_bin_and_libs ${pkgs.util-linux}/bin/losetup
          copy_bin_and_libs ${pkgs.util-linux}/bin/blkid
          copy_bin_and_libs ${pkgs.util-linux}/bin/findfs
        '';

        # Live boot logic: find the ISO, mount squashfs, set up overlayfs
        boot.initrd.postDeviceCommands = ''
          echo "ekaos live boot: searching for ISO filesystem..."

          # Wait for the ISO device to appear (USB/CD may be slow)
          for i in $(seq 1 30); do
            ISO_DEV=$(blkid -L "${options.volumeID}" 2>/dev/null || true)
            if [ -n "$ISO_DEV" ]; then
              break
            fi
            echo "  waiting for device with label ${options.volumeID}... ($i/30)"
            sleep 1
          done

          if [ -z "$ISO_DEV" ]; then
            echo "error: could not find device with label '${options.volumeID}'"
            echo "Available block devices:"
            blkid || true
            echo "Dropping to emergency shell..."
            exec /bin/sh
          fi

          echo "Found ISO at $ISO_DEV"

          # Mount the ISO filesystem
          mkdir -p /mnt-iso
          mount -t iso9660 -o ro "$ISO_DEV" /mnt-iso

          # Verify the squashfs image exists
          if [ ! -f /mnt-iso/nix-store.squashfs ]; then
            echo "error: /nix-store.squashfs not found on ISO"
            echo "ISO contents:"
            ls -la /mnt-iso/
            exec /bin/sh
          fi

          # Set up the root filesystem as tmpfs
          mount -t tmpfs -o mode=0755 tmpfs /mnt-root

          # Create the nix store overlay structure
          mkdir -p /mnt-root/nix/.ro-store
          mkdir -p /mnt-root/nix/.rw-store/store
          mkdir -p /mnt-root/nix/.rw-store/work
          mkdir -p /mnt-root/nix/store

          # Mount the squashfs as the read-only lower layer
          mount -t squashfs -o loop,ro /mnt-iso/nix-store.squashfs /mnt-root/nix/.ro-store

          # Mount a tmpfs for the writable upper layer
          mount -t tmpfs -o mode=0755 tmpfs /mnt-root/nix/.rw-store

          # Re-create work/store dirs after tmpfs mount
          mkdir -p /mnt-root/nix/.rw-store/store
          mkdir -p /mnt-root/nix/.rw-store/work

          # Set up the overlay
          mount -t overlay overlay \
            -o lowerdir=/mnt-root/nix/.ro-store,upperdir=/mnt-root/nix/.rw-store/store,workdir=/mnt-root/nix/.rw-store/work \
            /mnt-root/nix/store

          # Create essential directories in the tmpfs root
          mkdir -p /mnt-root/{bin,etc,home,proc,run,sys,dev,tmp,var,usr}
          chmod 1777 /mnt-root/tmp

          # Bind the ISO so it stays accessible after switch_root
          mkdir -p /mnt-root/iso
          mount --move /mnt-iso /mnt-root/iso

          echo "ekaos live boot: nix store overlay ready"
        '';

        boot.initrd.postMountCommands = ''
          echo "ekaos live boot: preparing switch_root..."
        '';

        isoImage.storeContents = storeContents;

        # TODO(adios-cutover): stringAfter [ "etc" ] ordering dropped.
        system.activationScripts.register-iso-nix-paths = ''
          if [ -f /nix/store/nix-path-registration ]; then
            ${inputs.nixCfg.nix.package}/bin/nix-store --load-db < /nix/store/nix-path-registration
          fi

          # Create system profile
          touch /etc/EKAOS
          ${inputs.nixCfg.nix.package}/bin/nix-env -p /nix/var/nix/profiles/system --set /run/current-system
        '';

        # Legacy internal option system.build.isoImage.
        system.build.isoImage = import ../../lib/make-iso9660-image.nix {
          # TODO(adios-cutover): helper rewrite pending (HELPER:
          # lib/make-iso9660-image.nix); path resolves once mirrored at
          # ekaos/adios/lib/make-iso9660-image.nix. nixpkgs lib passed via
          # pkgs.lib until then.
          inherit pkgs;
          lib = pkgs.lib;
          compressImage = options.compressImage;
          isoName = "${isoBaseName}.iso";
          volumeID = options.volumeID;
          squashfsContents = storeContents;
          squashfsCompression = options.squashfsCompression;
          efiBootImage = efiImg;
          contents = [
            {
              source = efiDir;
              target = "/EFI";
            }
            {
              source = efiImg;
              target = "/EFI/efiboot.img";
            }
            {
              source = pkgs.writeText "version" inputs.sys.system.ekaos.version;
              target = "/version.txt";
            }
          ]
          ++ options.contents;
        };
      };
}
