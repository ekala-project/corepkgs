{
  lib,
  buildXorgPackage,
  pkg-config,
  fetchurl,
  xorgproto,
  libinput ? null,
  xorg-server,
}:

buildXorgPackage (finalAttrs: {
  pname = "xf86-input-libinput";
  version = "1.5.0";
  src = fetchurl {
    url = "mirror://xorg/individual/driver/xf86-input-libinput-1.5.0.tar.xz";
    sha256 = "1rl06l0gdqmc4v08mya93m74ana76b7s3fzkmq8ylm3535gw6915";
  };
  nativeBuildInputs = [ pkg-config ];
  buildInputs = [
    xorgproto
    libinput
    xorg-server
  ];
  outputs = [
    "out"
    "dev"
  ];
  configureFlags = [ "--with-sdkdir=${placeholder "dev"}/include/xorg" ];
  meta = {
    pkgConfigModules = [ "xorg-libinput" ];
  };
})
