{
  lib,
  stdenv,
  fetchFromGitHub,
  fetchpatch,
  autoreconfHook,
  libxext,
  libx11,
  ncurses,
  pkg-config,
  zlib,
  x11Support ? !stdenv.hostPlatform.isDarwin,
}:

stdenv.mkDerivation rec {
  pname = "libcaca";
  version = "0.99.beta20";

  src = fetchFromGitHub {
    owner = "cacalabs";
    repo = "libcaca";
    rev = "v${version}";
    hash = "sha256-N0Lfi0d4kjxirEbIjdeearYWvStkKMyV6lgeyNKXcVw=";
  };

  patches = [
    (fetchpatch {
      name = "CVE-2026-42046.patch";
      url = "https://github.com/cacalabs/libcaca/commit/fb77acff9ba6bb01d53940da34fb10f20b156a23.patch";
      hash = "sha256-AdpiE5Gw/CVET//7TTYZCb0glW5HY+T8xZkYs1XCBvY=";
    })
  ];

  nativeBuildInputs = [
    autoreconfHook
    pkg-config
  ];

  buildInputs = [
    ncurses
    zlib
  ]
  ++ lib.optionals x11Support [
    libx11
    libxext
  ];

  outputs = [
    "bin"
    "dev"
    "out"
    "man"
  ];

  configureFlags = [
    "--disable-imlib2"
    "--disable-doc"
    "--disable-cpplibs"
    "--disable-java"
    "--disable-csharp"
    "--disable-python"
    "--disable-ruby"
    (if x11Support then "--enable-x11" else "--disable-x11")
  ];

  # cacaview and img2txt link against internal _caca_alloc2d which is not exported
  postConfigure = ''
    sed -i 's/cacaview\$(EXEEXT)//g; s/img2txt\$(EXEEXT)//g' src/Makefile
    sed -i 's/trifiller\$(EXEEXT)//g' examples/Makefile
  '';

  env.NIX_CFLAGS_COMPILE = lib.optionalString (!x11Support) "-DX_DISPLAY_MISSING";

  postInstall = ''
    mkdir -p $dev/bin
    mv $bin/bin/caca-config $dev/bin/caca-config
  '';

  meta = {
    homepage = "http://caca.zoy.org/wiki/libcaca";
    description = "Graphics library that outputs text instead of pixels";
    license = lib.licenses.wtfpl;
    platforms = lib.platforms.unix;
  };
}
