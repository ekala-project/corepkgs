{
  lib,
  stdenv,
  fetchurl,
  nasm,
  nasmSupport ? true,
  cpmlSupport ? true,
  decoderSupport ? true,
  frontendSupport ? true,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "lame";
  version = "3.100";

  src = fetchurl {
    url = "mirror://sourceforge/lame/lame-${finalAttrs.version}.tar.gz";
    sha256 = "07nsn5sy3a8xbmw1bidxnsj5fj6kg9ai04icmqw40ybkp353dznx";
  };

  outputs = [
    "out"
    "lib"
    "doc"
  ];
  outputMan = "out";

  nativeBuildInputs = lib.optional nasmSupport nasm;

  configureFlags = [
    (lib.enableFeature nasmSupport "nasm")
    (lib.enableFeature cpmlSupport "cpml")
    "--with-fileio=lame"
    "--enable-analyzer-hooks"
    (lib.enableFeature decoderSupport "decoder")
    (lib.enableFeature frontendSupport "frontend")
    (lib.enableFeature frontendSupport "dynamic-frontends")
  ];

  preConfigure = ''
    # Prevent a build failure for 3.100 due to using outdated symbol list
    sed -i '/lame_init_old/d' include/libmp3lame.sym
  '';

  meta = {
    description = "High quality MPEG Audio Layer III (MP3) encoder";
    homepage = "http://lame.sourceforge.net";
    license = lib.licenses.lgpl2;
    platforms = lib.platforms.all;
    mainProgram = "lame";
  };
})
