{
  lib,
  stdenv,
  fetchurl,
  pkg-config,
  meson,
  ninja,
  zlib,
  hwdata,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "libpciaccess";
  version = "0.18.1";

  src = fetchurl {
    url = "mirror://xorg/individual/lib/libpciaccess-${finalAttrs.version}.tar.xz";
    hash = "sha256-SvQ0RLOK21VF0O0cLORtlgjMR7McI4f8UYFlZ2Wm+nY=";
  };

  strictDeps = true;

  nativeBuildInputs = [
    pkg-config
    meson
    meson.configurePhaseHook
    ninja
  ];

  buildInputs = [
    zlib
  ];

  mesonFlags = [
    (lib.mesonOption "pci-ids" "${hwdata}/share/hwdata")
    (lib.mesonEnable "zlib" true)
  ];

  meta = {
    description = "Generic PCI access library";
    homepage = "https://gitlab.freedesktop.org/xorg/lib/libpciaccess";
    license = with lib.licenses; [
      mit
      isc
      x11
    ];
    platforms = lib.platforms.linux ++ lib.platforms.freebsd ++ lib.platforms.openbsd;
  };
})
