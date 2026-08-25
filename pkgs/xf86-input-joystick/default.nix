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
  pname = "xf86-input-joystick";
  version = "1.6.4";
  src = fetchurl {
    url = "mirror://xorg/individual/driver/xf86-input-joystick-1.6.4.tar.xz";
    sha256 = "1lnc6cvrg81chb2hj3jphgx7crr4ab8wn60mn8f9nsdwza2w8plh";
  };
  nativeBuildInputs = [ pkg-config ];
  buildInputs = [
    xorgproto
    xorg-server
  ];
  configureFlags = [ "--with-sdkdir=${placeholder "out"}/include/xorg" ];
  meta = {
    pkgConfigModules = [ "xorg-joystick" ];
    broken = stdenv.hostPlatform.isDarwin;
  };
})
