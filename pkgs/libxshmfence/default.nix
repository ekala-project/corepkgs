{
  lib,
  stdenv,
  fetchurl,
  pkg-config,
  xorgproto,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "libxshmfence";
  version = "1.3.3";

  outputs = [
    "out"
    "dev"
  ];

  src = fetchurl {
    url = "mirror://xorg/individual/lib/libxshmfence-${finalAttrs.version}.tar.xz";
    hash = "sha256-1KTfCWq6lv6gLAKe46ROEaR+t/chPBpym+g+hew/3hA=";
  };

  strictDeps = true;

  nativeBuildInputs = [ pkg-config ];

  buildInputs = [ xorgproto ];

  meta = {
    description = "Shared memory 'SyncFence' synchronization primitive library";
    homepage = "https://gitlab.freedesktop.org/xorg/lib/libxshmfence";
    license = lib.licenses.hpndSellVariant;
    maintainers = [ ];
    pkgConfigModules = [ "xshmfence" ];
    platforms = lib.platforms.unix;
  };
})
