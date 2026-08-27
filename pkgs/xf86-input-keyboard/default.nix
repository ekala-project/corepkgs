{
  lib,
  buildXorgPackage,
  pkg-config,
  fetchurl,
  xorgproto,
  xorg-server,
}:

buildXorgPackage (finalAttrs: {
  pname = "xf86-input-keyboard";
  version = "2.1.0";
  src = fetchurl {
    url = "mirror://xorg/individual/driver/xf86-input-keyboard-2.1.0.tar.xz";
    sha256 = "0mvwxrnkq0lzhjr894p420zxffdn34nc2scinmp7qd1hikr51kkp";
  };
  nativeBuildInputs = [ pkg-config ];
  buildInputs = [
    xorgproto
    xorg-server
  ];
  meta.platforms = lib.platforms.freebsd ++ lib.platforms.netbsd ++ lib.platforms.openbsd;
  meta.identifiers.cpeParts.vendor = "x.org";
})
