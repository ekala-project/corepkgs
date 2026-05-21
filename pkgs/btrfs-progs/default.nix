{
  lib,
  stdenv,
  fetchurl,
  pkg-config,
  util-linux,
  e2fsprogs,
  zlib,
  lzo,
  zstd,
  python3,
  eudev,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "btrfs-progs";
  version = "7.0";

  src = fetchurl {
    url = "mirror://kernel/linux/kernel/people/kdave/btrfs-progs/btrfs-progs-v${finalAttrs.version}.tar.xz";
    hash = "sha256-wobWh2y81yMnoLQX5M/SgDU+wj43tUn9vNeACoMtmpk=";
  };

  outputs = [
    "out"
    "dev"
    # No man output since we disabled documentation
  ];

  nativeBuildInputs = [
    pkg-config
    python3
  ];

  buildInputs = [
    util-linux # libuuid, libblkid
    e2fsprogs # ext2fs
    zlib
    lzo
    zstd
    eudev # libudev
  ];

  # btrfs-progs uses autotools
  configureFlags = [
    "--disable-backtrace" # Requires libunwind
    "--disable-documentation" # We'll use pre-built man pages
    "--disable-python" # Don't build Python bindings (would need setuptools)
  ];

  enableParallelBuilding = true;

  # Default install target should work
  # (btrfs-progs doesn't have install_dev like xfsprogs)

  # Redirect udev rules to our output
  installFlags = [
    "udevdir=${placeholder "out"}/lib/udev"
  ];

  meta = {
    homepage = "https://btrfs.readthedocs.io/";
    description = "Utilities for the btrfs filesystem";
    longDescription = ''
      Btrfs is a modern copy-on-write (CoW) filesystem for Linux aimed at
      implementing advanced features while also focusing on fault tolerance,
      repair, and easy administration.

      This package provides utilities for managing btrfs filesystems, including:
      - mkfs.btrfs: Create a btrfs filesystem
      - btrfs: Main administration tool for subvolumes, snapshots, etc.
      - btrfs-convert: Convert ext2/3/4 filesystems to btrfs
      - btrfs check: Check and repair btrfs filesystems
      - btrfstune: Tune btrfs filesystem parameters

      Key features of btrfs:
      - Snapshots and subvolumes
      - Compression (zlib, lzo, zstd)
      - RAID support (RAID0, RAID1, RAID10, RAID5, RAID6)
      - Online filesystem defragmentation
      - Online volume management
      - Self-healing (checksums and redundancy)
    '';
    license = lib.licenses.gpl2Plus;
    platforms = lib.platforms.linux;
    maintainers = [ ];
  };
})
