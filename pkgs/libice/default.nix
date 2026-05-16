{
  lib,
  stdenv,
  fetchurl,
  pkg-config,
  xorgproto,
  xtrans,
  testers,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "libice";
  version = "1.1.2";

  outputs = [
    "out"
    "dev"
    "doc"
  ];

  src = fetchurl {
    url = "mirror://xorg/individual/lib/libICE-${finalAttrs.version}.tar.xz";
    hash = "sha256-l05O1BQiXrPHFphd+XCfTajSKmeiiQBmvG38ia0phiU=";
  };

  nativeBuildInputs = [ pkg-config ];

  buildInputs = [
    xorgproto
    xtrans
  ];

  propagatedBuildInputs = [
    xorgproto
  ];

  meta = {
    description = "X Inter-Client Exchange library";
    homepage = "https://gitlab.freedesktop.org/xorg/lib/libice";
    license = with lib.licenses; [
      mit
      x11
    ];
    pkgConfigModules = [ "ice" ];
    platforms = lib.platforms.unix;
  };
})
