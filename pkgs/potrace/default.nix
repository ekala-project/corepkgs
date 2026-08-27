{
  lib,
  stdenv,
  fetchurl,
  zlib,
}:

stdenv.mkDerivation rec {
  pname = "potrace";
  version = "1.16";

  src = fetchurl {
    url = "https://potrace.sourceforge.net/download/${version}/potrace-${version}.tar.gz";
    hash = "sha256-voJIoX3t1sy6qy/MRYNbsFAtBi5A+97TvFYCjOXresw=";
  };

  configureFlags = [
    "--with-libpotrace"
  ];

  buildInputs = [
    zlib
  ];

  meta = {
    description = "Tool for tracing a bitmap into a smooth, scalable image";
    homepage = "https://potrace.sourceforge.net/";
    license = lib.licenses.gpl2Plus;
    platforms = lib.platforms.unix;
  };
}
