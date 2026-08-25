{
  lib,
  buildXorgPackage,
  pkg-config,
  fetchurl,
  libx11,
  libxkbfile,
  xorgproto,
  xkeyboard-config,
}:

buildXorgPackage (finalAttrs: {
  pname = "xkbcomp";
  version = "1.4.7";
  src = fetchurl {
    url = "mirror://xorg/individual/app/xkbcomp-1.4.7.tar.xz";
    sha256 = "0xqzz209m9i43jbyrf2lh4xdbyhzzzn9mis2f2c32kplwla82a0a";
  };
  nativeBuildInputs = [ pkg-config ];
  buildInputs = [
    libx11
    libxkbfile
    xorgproto
  ];
  configureFlags = [ "--with-xkb-config-root=${xkeyboard-config}/share/X11/xkb" ];
  meta = {
    pkgConfigModules = [ "xkbcomp" ];
    mainProgram = "xkbcomp";
  };
})
