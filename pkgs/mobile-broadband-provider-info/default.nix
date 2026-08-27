{
  lib,
  stdenv,
  fetchurl,
  libxslt,
  libxml2,
  meson,
  ninja,
}:

stdenv.mkDerivation rec {
  pname = "mobile-broadband-provider-info";
  version = "20240407";

  src = fetchurl {
    url = "mirror://gnome/sources/${pname}/${version}/${pname}-${version}.tar.xz";
    hash = "sha256-ib/v8hX0v/jpw/8uwlJQ/bCA0R6b+lnG/HGYKsAcgUo=";
  };

  nativeBuildInputs = [
    libxslt
    libxml2
    meson
    meson.configurePhaseHook
    ninja
  ];

  mesonBuildType = "release";

  meta = {
    description = "Mobile broadband service provider database";
    homepage = "https://gitlab.gnome.org/GNOME/mobile-broadband-provider-info";
    license = lib.licenses.publicDomain;
    platforms = lib.platforms.all;
  };
}
