{
  lib,
  buildXorgPackage,
  stdenv,
  pkg-config,
  fetchurl,
  xorg-server,
  xorgproto,
}:

buildXorgPackage (finalAttrs: {
  pname = "xf86-input-void";
  version = "1.4.2";
  src = fetchurl {
    url = "mirror://xorg/individual/driver/xf86-input-void-1.4.2.tar.xz";
    sha256 = "11bqy2djgb82c1g8ylpfwp3wjw4x83afi8mqyn5fvqp03kidh4d2";
  };
  nativeBuildInputs = [ pkg-config ];
  buildInputs = [
    xorg-server
    xorgproto
  ];
  meta.broken = stdenv.hostPlatform.isDarwin;
})
