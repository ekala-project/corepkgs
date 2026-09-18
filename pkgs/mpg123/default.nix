{
  lib,
  stdenv,
  fetchurl,
  pkg-config,
  alsa-lib,
  libOnly ? true,
  alsaSupport ? stdenv.hostPlatform.isLinux,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "${lib.optionalString libOnly "lib"}mpg123";
  version = "1.33.7";

  src = fetchurl {
    url = "mirror://sourceforge/mpg123/mpg123-${finalAttrs.version}.tar.bz2";
    hash = "sha256-MdDjWkylZ+ybXr2mwwYrtENdbT6s1u8NlcrdeFTcA+4=";
  };

  outputs = [
    "out"
    "dev"
    "man"
  ];

  nativeBuildInputs = lib.optionals (!libOnly && alsaSupport) [ pkg-config ];

  buildInputs = lib.optionals (!libOnly && alsaSupport) [ alsa-lib ];

  configureFlags =
    lib.optionals (!libOnly) [
      "--with-audio=${lib.strings.concatStringsSep "," (lib.optional alsaSupport "alsa" ++ [ "dummy" ])}"
    ]
    ++ lib.optional (stdenv.hostPlatform ? mpg123) "--with-cpu=${stdenv.hostPlatform.mpg123.cpu}";

  enableParallelBuilding = true;

  meta = {
    description = "Fast console MPEG Audio Player and decoder library";
    homepage = "https://mpg123.org";
    license = lib.licenses.lgpl21Only;
    platforms = lib.platforms.all;
  };
})
