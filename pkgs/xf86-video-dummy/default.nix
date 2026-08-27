{
  lib,
  buildXorgPackage,
  stdenv,
  pkg-config,
  fetchurl,
  xorgproto,
  xorg-server,
}:

buildXorgPackage (finalAttrs: {
  pname = "xf86-video-dummy";
  version = "0.4.1";
  src = fetchurl {
    url = "mirror://xorg/individual/driver/xf86-video-dummy-0.4.1.tar.xz";
    sha256 = "1byzsdcnlnzvkcqrzaajzc3nzm7y7ydrk9bjr4x9lx8gznkj069m";
  };
  nativeBuildInputs = [ pkg-config ];
  buildInputs = [
    xorgproto
    xorg-server
  ];
  meta.broken = stdenv.hostPlatform.isDarwin;
  meta.identifiers.cpeParts.vendor = "x.org";
})
