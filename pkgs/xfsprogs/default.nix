{
  lib,
  stdenv,
  fetchurl,
  pkg-config,
  util-linux,
  gettext,
  readline,
  inih,
  userspace-rcu,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "xfsprogs";
  version = "6.11.0";

  src = fetchurl {
    url = "mirror://kernel/linux/utils/fs/xfs/xfsprogs/xfsprogs-${finalAttrs.version}.tar.xz";
    hash = "sha256-2uO7QyGW97GDsua9XcRL8z7b19DoW9N9JcI134G4EAo=";
  };

  outputs = [
    "out"
    "dev"
    "man"
  ];

  nativeBuildInputs = [
    pkg-config
    gettext
  ];

  buildInputs = [
    util-linux # provides libuuid
    readline
    inih
    userspace-rcu
  ];

  enableParallelBuilding = true;

  # XFS uses a custom build system
  preConfigure = ''
    patchShebangs ./install-sh

    # Fix hardcoded paths
    sed -i "s|/usr/local|$out|" include/builddefs.in
    sed -i "s|/usr|$out|" include/builddefs.in
  '';

  configureFlags = [
    "--disable-static"
    "--enable-readline"
    "--with-systemd-unit-dir=${placeholder "out"}/lib/systemd/system"
  ];

  installFlags = [
    "install-dev"
  ];

  # Remove install-sh from final package
  postInstall = ''
    find $out -type f -name install-sh -delete
  '';

  # Fix RPATH issues - xfsprogs build system leaves build paths in binaries
  # We need to fix this before the automated RPATH check in fixupPhase
  preFixup = ''
    # Remove any references to /build/ in RPATH
    for binary in $out/sbin/*; do
      if [ -f "$binary" ] && [ -x "$binary" ]; then
        patchelf --shrink-rpath "$binary" || true
        patchelf --set-rpath "$out/lib:${
          lib.makeLibraryPath [
            readline
            userspace-rcu
            util-linux
            inih
          ]
        }" "$binary" || true
      fi
    done
  '';

  meta = {
    homepage = "https://xfs.wiki.kernel.org/";
    description = "SGI XFS utilities";
    longDescription = ''
      XFS is a high-performance journaling filesystem created by Silicon Graphics, Inc.

      xfsprogs contains utilities for managing XFS filesystems, including:
      - mkfs.xfs: Create an XFS filesystem
      - xfs_repair: Repair a corrupted or damaged XFS filesystem
      - xfs_db: Debug and examine an XFS filesystem
      - xfs_admin: Change parameters of an XFS filesystem
    '';
    license = lib.licenses.lgpl21Plus;
    platforms = lib.platforms.linux;
    maintainers = [ ];
  };
})
