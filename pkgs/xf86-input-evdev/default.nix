{
  lib,
  buildXorgPackage,
  pkg-config,
  fetchurl,
  xorgproto,
  libevdev ? null,
  udev,
  mtdev ? null,
  xorg-server,
}:

buildXorgPackage (finalAttrs: {
  pname = "xf86-input-evdev";
  version = "2.11.0";
  src = fetchurl {
    url = "mirror://xorg/individual/driver/xf86-input-evdev-2.11.0.tar.xz";
    sha256 = "058k0xdf4hkn8lz5gx4c08mgbzvv58haz7a32axndhscjgg2403k";
  };
  nativeBuildInputs = [ pkg-config ];
  buildInputs = [
    xorgproto
    libevdev
    udev
    mtdev
    xorg-server
  ];
  outputs = [
    "out"
    "dev"
  ];
  preBuild = "sed -e '/motion_history_proc/d; /history_size/d;' -i src/*.c";
  configureFlags = [ "--with-sdkdir=${placeholder "dev"}/include/xorg" ];
  meta = {
    pkgConfigModules = [ "xorg-evdev" ];
  };
})
