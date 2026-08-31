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
  pname = "grep-static";
  version = "3.12";

  src = fetchurl {
    url = "mirror://gnu/grep/grep-${version}.tar.xz";
    hash = "sha256-JkmyfA6Q5jLq3NdXvgbG6aT0jZQd5R58D4P/dkCKB7k=";
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
        ${result}/bin/grep --version
        mkdir $out
      '';

    meta = {
      description = "GNU implementation of the Unix grep command";
      homepage = "https://www.gnu.org/software/grep";
      license = lib.licenses.gpl3Plus;
      mainProgram = "grep";
      platforms = lib.platforms.unix;
    };
  }
  ''
    # Unpack
    tar xf ${src}
    cd grep-${version}

    # Configure
    bash ./configure \
      --prefix=$out \
      --build=${buildPlatform.config} \
      --host=${hostPlatform.config} \
      --disable-dependency-tracking \
      --disable-nls

    # Build
    make -j $NIX_BUILD_CORES

    # Install
    make -j $NIX_BUILD_CORES install-strip

    # Remove documentation not needed in the bootstrap chain.
    rm -rf $out/share
  ''
