{
  lib,
  stdenv,
  fetchurl,
  fetchpatch,
  pkg-config,
  lvm2,
  libuuid,
  gettext,
  readline,
  dosfstools,
  e2fsprogs,
  perl,
  python3,
  util-linux,
  check,
  testers,
  enableStatic ? stdenv.hostPlatform.isStatic,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "parted";
  version = "3.8";

  src = fetchurl {
    url = "mirror://gnu/parted/parted-${finalAttrs.version}.tar.xz";
    sha256 = "sha256-oreBH0ew3bH3sdCqRW98EnDacHCM4jHC/gVMcZnq+mM=";
  };

  outputs = [
    "out"
    "dev"
    "man"
    "info"
  ];

  postPatch = ''
    patchShebangs tests
  '';

  nativeBuildInputs = [ pkg-config ];

  buildInputs = [
    libuuid
  ]
  ++ lib.optional (readline != null) readline
  ++ lib.optional (gettext != null) gettext
  ++ lib.optional (lvm2 != null) lvm2;

  configureFlags =
    (if (readline != null) then [ "--with-readline" ] else [ "--without-readline" ])
    ++ lib.optional (lvm2 == null) "--disable-device-mapper"
    ++ lib.optional enableStatic "--enable-static";

  # Tests were previously failing due to Hydra running builds as uid 0.
  # That should hopefully be fixed now.
  doCheck = !stdenv.hostPlatform.isMusl; # translation test
  nativeCheckInputs = [
    check
    dosfstools
    e2fsprogs
    perl
    python3
    util-linux
  ];

  passthru.tests = {
    version = testers.testVersion {
      package = finalAttrs.finalPackage;
      command = "parted --version";
    };
  };

  meta = {
    description = "Create, destroy, resize, check, and copy partitions";

    longDescription = ''
      GNU Parted is an industrial-strength package for creating, destroying,
      resizing, checking and copying partitions, and the file systems on
      them.  This is useful for creating space for new operating systems,
      reorganising disk usage, copying data on hard disks and disk imaging.

      It contains a library, libparted, and a command-line frontend, parted,
      which also serves as a sample implementation and script backend.
    '';

    homepage = "https://www.gnu.org/software/parted/";
    license = lib.licenses.gpl3Plus;

    # GNU Parted requires libuuid, which is part of util-linux-ng.
    platforms = lib.platforms.linux;
  };
})
