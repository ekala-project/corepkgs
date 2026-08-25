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
  pname = "xf86-input-mouse";
  version = "1.9.5";
  src = fetchurl {
    url = "mirror://xorg/individual/driver/xf86-input-mouse-1.9.5.tar.xz";
    sha256 = "0s4rzp7aqpbqm4474hg4bz7i7vg3ir93ck2q12if4lj3nklqmpjg";
  };
  nativeBuildInputs = [ pkg-config ];
  buildInputs = [
    xorgproto
    xorg-server
  ];
  configureFlags = [ "--with-sdkdir=${placeholder "out"}/include/xorg" ];
  meta = {
    pkgConfigModules = [ "xorg-mouse" ];
    broken = stdenv.hostPlatform.isDarwin;
  };
})
