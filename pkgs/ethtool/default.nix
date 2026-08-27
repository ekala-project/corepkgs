{
  lib,
  stdenv,
  fetchurl,
  libmnl,
  pkg-config,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "ethtool";
  version = "7.1";

  src = fetchurl {
    url = "mirror://kernel/software/network/ethtool/ethtool-${finalAttrs.version}.tar.xz";
    hash = "sha256-TXjCbtwCVbyS9LmVtf1mEI11/5Zu1GlPYCWm03C8JJY=";
  };

  nativeBuildInputs = [
    pkg-config
  ];

  buildInputs = [
    libmnl
  ];

  enableParallelBuilding = true;

  meta = {
    description = "Utility for controlling network drivers and hardware";
    homepage = "https://www.kernel.org/pub/software/network/ethtool/";
    license = lib.licenses.gpl2Plus;
    platforms = lib.platforms.linux;
  };
})
