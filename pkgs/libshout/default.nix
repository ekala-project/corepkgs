{
  lib,
  stdenv,
  fetchurl,
  fetchpatch,
  pkg-config,
  openssl,
  libvorbis,
  libtheora,
  speex,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "libshout";
  version = "2.4.6";

  src = fetchurl {
    url = "https://downloads.xiph.org/releases/libshout/libshout-${finalAttrs.version}.tar.gz";
    sha256 = "sha256-OcvU8O/f3cl1XYghfkf48tcQj6dn+dWKK6JqFtj3yRA=";
  };

  patches = [
    (fetchpatch {
      url = "https://gitlab.xiph.org/xiph/icecast-libshout/-/commit/600fa105a799986efcccddfedfdfd3e9a1988cd0.patch";
      hash = "sha256-XjogfcQJBPZX9MPAbNJyXaFZNekL1pabvtTT7N+cz+s=";
    })
    (fetchpatch {
      url = "https://gitlab.xiph.org/xiph/icecast-libshout/-/commit/8ab2de318d55c9d0987ffae7d9b94b365af732c1.patch";
      hash = "sha256-0+Wp2Xu59ESCJfoDcwAJHuAJyzMsaBe7f8Js3/ren2g=";
    })
  ];

  outputs = [
    "out"
    "dev"
    "doc"
  ];

  depsBuildBuild = [ pkg-config ];
  nativeBuildInputs = [ pkg-config ];
  propagatedBuildInputs = [
    openssl
    libvorbis
    libtheora
    speex
  ];

  meta = {
    description = "Icecast C language bindings";
    homepage = "https://www.icecast.org";
    license = lib.licenses.gpl2;
    platforms = lib.platforms.unix;
  };
})
