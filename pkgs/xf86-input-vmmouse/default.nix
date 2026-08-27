{
  lib,
  buildXorgPackage,
  pkg-config,
  fetchurl,
  xorgproto,
  udev,
  xorg-server,
}:

buildXorgPackage (finalAttrs: {
  pname = "xf86-input-vmmouse";
  version = "13.2.0";
  src = fetchurl {
    url = "mirror://xorg/individual/driver/xf86-input-vmmouse-13.2.0.tar.xz";
    sha256 = "1f1rlgp1rpsan8k4ax3pzhl1hgmfn135r31m80pjxw5q19c7gw2n";
  };
  nativeBuildInputs = [ pkg-config ];
  buildInputs = [
    xorgproto
    udev
    xorg-server
  ];
  configureFlags = [
    "--sysconfdir=${placeholder "out"}/etc"
    "--with-xorg-conf-dir=${placeholder "out"}/share/X11/xorg.conf.d"
    "--with-udev-rules-dir=${placeholder "out"}/lib/udev/rules.d"
  ];
  meta.platforms = [
    "i686-linux"
    "x86_64-linux"
  ];
  meta.identifiers.cpeParts.vendor = "x.org";
})
