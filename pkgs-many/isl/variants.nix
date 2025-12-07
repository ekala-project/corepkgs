{
  v0_20 = rec {
    version = "0.20";
    src-urls = [
      "mirror://sourceforge/libisl/isl-${version}.tar.xz"
      "https://libisl.sourceforge.io/isl-${version}.tar.xz"
    ];
    src-hash = "sha256-pVlqn7ils2XLYS5LlihzXW5n6RePrhNKgWrhlQF+d6o=";
    configureFlags = [
      "--with-gcc-arch=generic" # don't guess -march=/mtune=
    ];
  };
  v0_23 = rec {
    version = "0.23";
    src-urls = [
      "mirror://sourceforge/libisl/isl-${version}.tar.xz"
      "https://libisl.sourceforge.io/isl-${version}.tar.xz"
    ];
    src-hash = "sha256-XvxT767xUTAfTn3eOFa2aBLYFT3t4k+rF2c/gByGmPI=";
    configureFlags = [
      "--with-gcc-arch=generic" # don't guess -march=/mtune=
    ];
  };
  v0_27 = rec {
    version = "0.27";
    src-urls = [
      "mirror://sourceforge/libisl/isl-${version}.tar.xz"
      "https://libisl.sourceforge.io/isl-${version}.tar.xz"
    ];
    src-hash = "sha256-bYurtZ57Zy6Mt4cOh08/e4E7bgDmrz+LBPdXmWVkPVw=";
    configureFlags = [
      "--with-gcc-arch=generic" # don't guess -march=/mtune=
    ];
  };
}
