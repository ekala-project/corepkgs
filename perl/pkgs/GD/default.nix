{
  buildPerlPackage,
  ExtUtilsPkgConfig,
  fetchurl,
  fontconfig,
  freetype,
  gd,
  libjpeg,
  libpng,
  libxpm,
  pkg-config,
  TestFork,
  TestNoWarnings,
  zlib,
}:

buildPerlPackage {
  pname = "GD";
  version = "2.78";
  src = fetchurl {
    url = "mirror://cpan/authors/id/R/RU/RURBAN/GD-2.78.tar.gz";
    hash = "sha256-aDEFS/VCS09cI9NifT0UhEgPb5wsZmMiIpFfKFG+buQ=";
  };

  nativeBuildInputs = [
    pkg-config
  ];
  buildInputs = [
    gd
    libjpeg
    zlib
    freetype
    libpng
    fontconfig
    libxpm
    ExtUtilsPkgConfig
    TestFork
    TestNoWarnings
  ];

  # otherwise "cc1: error: -Wformat-security ignored without -Wformat [-Werror=format-security]"
  hardeningDisable = [ "format" ];

  makeMakerFlags = [
    "--lib_png_path=${libpng.out}"
    "--lib_jpeg_path=${libjpeg.out}"
    "--lib_zlib_path=${zlib.out}"
    "--lib_ft_path=${freetype.out}"
    "--lib_fontconfig_path=${fontconfig.lib}"
    "--lib_xpm_path=${libxpm.out}"
  ];

  meta = {
    description = "Perl interface to the gd2 graphics library";
    mainProgram = "bdf2gdfont.pl";
  };
}
