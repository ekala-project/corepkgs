{
  v0_11 = {
    version = "0.11.1";
    src-urls = [
      "https://src.fedoraproject.org/repo/pkgs/gcc/isl-0.11.1.tar.bz2/bce1586384d8635a76d2f017fb067cd2/isl-0.11.1.tar.bz2"
    ];
    src-hash = "sha256-CV9LVMiMoTqA0rAl2cVR+J6num9iAdcBlgv+XBRmqY0=";
    patches = [ ./fix-gcc-build.diff ];
  };
  v0_14 = rec {
    version = "0.14.1";
    src-urls = [
      "mirror://sourceforge/libisl/isl-${version}.tar.xz"
      "https://libisl.sourceforge.io/isl-${version}.tar.xz"
    ];
    src-hash = "sha256-iILJ42VJ/HV++iZ3Bqmvczu41/45Bcv95D4XqJ7qRnU=";
  };

  v0_17 = rec {
    version = "0.17.1";
    src-urls = [
      "mirror://sourceforge/libisl/isl-${version}.tar.xz"
      "https://libisl.sourceforge.io/isl-${version}.tar.xz"
    ];
    src-hash = "sha256-vhUuXIFrR3WU9MYZS1Zm2BKfOidwJ1aun/YDRqhzFkc=";
  };
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
}
