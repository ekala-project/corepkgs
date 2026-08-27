{
  lib,
  stdenv,
  fetchFromGitLab,
  util-macros,
  autoreconfHook,
  pkg-config,
  xorgproto,
  testers,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "libxshmfence";
  version = "1.3.3";

  outputs = [
    "out"
    "dev"
  ];

  src = fetchFromGitLab {
    domain = "gitlab.freedesktop.org";
    group = "xorg";
    owner = "lib";
    repo = "libxshmfence";
    tag = "libxshmfence-${finalAttrs.version}";
    hash = "sha256-Aw+HPt1gQ4Q13/MXsFKCr+Eah2CCNEbF1lABjHn4swM=";
  };

  strictDeps = true;

  nativeBuildInputs = [
    autoreconfHook
    pkg-config
    util-macros
  ];

  buildInputs = [ xorgproto ];

  passthru = {
    tests.pkg-config = testers.testMetaPkgConfig finalAttrs.finalPackage;
  };

  meta = {
    description = "Shared memory 'SyncFence' synchronization primitive library";
    longDescription = ''
      This library offers a CPU-based synchronization primitive compatible with the X SyncFence
      objects that can be shared between processes using file descriptor passing.
      There are two underlying implementations:
      - On Linux, the library uses futexes
      - On other systems, the library uses posix mutexes and condition variables.
    '';
    homepage = "https://gitlab.freedesktop.org/xorg/lib/libxshmfence";
    license = lib.licenses.hpndSellVariant;
    pkgConfigModules = [ "xshmfence" ];
    platforms = lib.platforms.unix;
    identifiers.cpeParts = lib.meta.cpeFullVersionWithVendor "x.org" finalAttrs.version;
  };
})
