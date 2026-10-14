{
  lib,
  stdenv,
  fetchurl,
  libxslt,
  libxml2,
  meson,
  ninja,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "mobile-broadband-provider-info";
  version = "20240407";

  src = fetchurl {
    url = "mirror://gnome/sources/mobile-broadband-provider-info/${finalAttrs.version}/mobile-broadband-provider-info-${finalAttrs.version}.tar.xz";
    hash = "sha256-ib/v8hX0v/jpw/8uwlJQ/bCA0R6b+lnG/HGYKsAcgUo=";
  };

  nativeBuildInputs = [
    libxslt
    libxml2
    meson
    meson.configurePhaseHook
    ninja
  ];

  meta = {
    description = "Mobile broadband service provider database";
    homepage = "https://gitlab.gnome.org/GNOME/mobile-broadband-provider-info";
    license = lib.licenses.publicDomain;
    platforms = lib.platforms.all;
  };
})
