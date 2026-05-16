{
  lib,
  stdenv,
  fetchurl,
  pkg-config,
  xorgproto,
  libice,
  libuuid,
  xtrans,
  testers,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "libsm";
  version = "1.2.5";

  outputs = [
    "out"
    "dev"
    "doc"
  ];

  src = fetchurl {
    url = "mirror://xorg/individual/lib/libSM-${finalAttrs.version}.tar.xz";
    hash = "sha256-KvnhLaXvZw3Dp7zhiVycDxv7DLnmTo20D8wz+IO9ILw=";
  };

  nativeBuildInputs = [ pkg-config ];

  buildInputs = [
    xorgproto
    libice
    libuuid
    xtrans
  ];

  propagatedBuildInputs = [
    xorgproto
    libice
  ];

  meta = {
    description = "X Session Management Library";
    homepage = "https://gitlab.freedesktop.org/xorg/lib/libsm";
    license = with lib.licenses; [
      mit
      x11
    ];
    pkgConfigModules = [ "sm" ];
    platforms = lib.platforms.unix;
  };
})
