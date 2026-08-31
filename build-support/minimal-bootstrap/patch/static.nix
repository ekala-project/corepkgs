{
  lib,
  buildPlatform,
  hostPlatform,
  fetchurl,
  bash,
  gcc,
  binutils,
  make,
  sed,
  grep,
  gawk,
  diffutils,
  findutils,
  tar,
  xz,
}:
let
  pname = "patch-static";
  version = "2.8";

  src = fetchurl {
    url = "mirror://gnu/patch/patch-${version}.tar.xz";
    hash = "sha256-+Hzuae7CtPy/YKOWsDCtaqNBXxkqpffuhMrV4R9/WuM=";
  };
in
bash.runCommand "${pname}-${version}"
  {
    inherit pname version;

    nativeBuildInputs = [
      gcc
      binutils
      make
      sed
      grep
      gawk
      diffutils
      findutils
      tar
      xz
    ];

    passthru.tests.get-version =
      result:
      bash.runCommand "${pname}-get-version-${version}" { } ''
        ${result}/bin/patch --version
        mkdir $out
      '';

    meta = {
      description = "GNU Patch, a program to apply differences to files";
      homepage = "https://www.gnu.org/software/patch";
      license = lib.licenses.gpl3Plus;
      mainProgram = "patch";
      platforms = lib.platforms.unix;
    };
  }
  ''
    # Unpack
    tar xf ${src}
    cd patch-${version}

    # Configure
    bash ./configure \
      --prefix=$out \
      --build=${buildPlatform.config} \
      --host=${hostPlatform.config} \
      --disable-dependency-tracking

    # Build
    make -j $NIX_BUILD_CORES

    # Install
    make -j $NIX_BUILD_CORES install-strip
    rm -rf $out/share
  ''
