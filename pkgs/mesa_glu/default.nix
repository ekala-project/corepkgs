{
  lib,
  stdenv,
  fetchurl,
  meson,
  ninja,
  pkg-config,
  libGL,
}:

stdenv.mkDerivation rec {
  pname = "glu";
  version = "9.0.3";

  src = fetchurl {
    url = "https://mesa.freedesktop.org/archive/glu/glu-${version}.tar.xz";
    hash = "sha256-vUP+EvN0sRkusV/iDkX/RWubwmq1fw7ukZ+Wyg+KMw8=";
  };

  nativeBuildInputs = [
    meson
    meson.configurePhaseHook
    ninja
    pkg-config
  ];

  propagatedBuildInputs = [
    libGL
  ];

  outputs = [
    "out"
    "dev"
  ];

  meta = {
    description = "OpenGL utility library";
    homepage = "https://cgit.freedesktop.org/mesa/glu/";
    license = lib.licenses.sgi-b-20;
    platforms = lib.platforms.unix;
    maintainers = [ ];
  };
}
