{
  lib,
  stdenv,
  fetchgit,
  autoreconfHook,
  pkg-config,
  cmocka,
  acl,
  libuuid,
  lzo,
  util-linux,
  zlib,
  zstd,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "mtd-utils";
  version = "2.3.0";

  src = fetchgit {
    url = "git://git.infradead.org/mtd-utils.git";
    rev = "v${finalAttrs.version}";
    hash = "sha256-qQ8r0LBxwzdT9q9ILxKD1AfzLimaNHdc9BT3Rox1eXs=";
  };

  nativeBuildInputs = [
    autoreconfHook
    pkg-config
  ]
  ++ lib.optional finalAttrs.doCheck cmocka;
  buildInputs = [
    acl
    libuuid
    lzo
    util-linux
    zlib
    zstd
  ];

  postPatch = ''
    substituteInPlace ubifs-utils/mount.ubifs \
      --replace-fail "/bin/mount" "${util-linux}/bin/mount"
  '';

  enableParallelBuilding = true;

  configureFlags = [
    (lib.enableFeature finalAttrs.doCheck "unit-tests")
    (lib.enableFeature finalAttrs.doCheck "tests")
  ];

  makeFlags = [ "AR:=$(AR)" ];

  doCheck = false;

  outputs = [
    "out"
    "dev"
  ];

  postInstall = ''
    mkdir -p $dev/lib
    mv *.a $dev/lib/
    mv include $dev/
  '';

  passthru.tests.unit = finalAttrs.finalPackage.overrideAttrs {
    doCheck = stdenv.buildPlatform.canExecute stdenv.hostPlatform;
  };

  meta = {
    description = "Tools for MTD filesystems";
    downloadPage = "https://git.infradead.org/mtd-utils.git";
    license = lib.licenses.gpl2Plus;
    homepage = "http://www.linux-mtd.infradead.org/";
    maintainers = [ ];
    platforms = with lib.platforms; linux;
  };
})
