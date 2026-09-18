{
  lib,
  stdenv,
  fetchurl,
  fetchpatch,
  updateAutotoolsGnuConfigScriptsHook,
  autoreconfHook,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "cdparanoia-iii";
  version = "10.2";

  src = fetchurl {
    url = "https://downloads.xiph.org/releases/cdparanoia/cdparanoia-III-${finalAttrs.version}.src.tgz";
    sha256 = "1pv4zrajm46za0f6lv162iqffih57a8ly4pc69f7y0gfyigb8p80";
  };

  patches = [
    ./fix_private_keyword.patch
    ./configure.patch
    (fetchpatch {
      url = "https://github.com/macports/macports-ports/raw/f210a6061bc53c746730a37922399c6de6d69cb7/audio/cdparanoia/files/fixing-labs.patch";
      hash = "sha256-BMMQ5bbPP3eevuwWUVjQCtRBiWbkAHD+O0C0fp+BPaw=";
    })
    (fetchpatch {
      url = "https://github.com/macports/macports-ports/raw/f210a6061bc53c746730a37922399c6de6d69cb7/audio/cdparanoia/files/fixing-fprintf.patch";
      hash = "sha256-2dJl16p+f5l3wxVOJhsuLiQ9a4prq7jsRZP8/ygEae4=";
    })
    (fetchpatch {
      url = "https://salsa.debian.org/optical-media-team/cdparanoia/-/raw/bbf353721834b3784ccc0fd54a36a6b25181f5a4/debian/patches/02-ide-devices.patch";
      hash = "sha256-S6OzftUIPPq9JHsoAE2K51ltsI1WkVaQrpgCjgm5AG4=";
    })
    (fetchpatch {
      url = "https://salsa.debian.org/optical-media-team/cdparanoia/-/raw/f7bab3024c5576da1fdb7497abbd6abc8959a98c/debian/patches/04-endian.patch";
      hash = "sha256-krfprwls0L3hsNfoj2j69J5k1RTKEQtzE0fLYG9EJKo=";
    })
    ./freebsd.patch
  ]
  ++ lib.optional stdenv.hostPlatform.isMusl ./utils.patch
  ++ lib.optional (!stdenv.hostPlatform.isDarwin) [
    (fetchpatch {
      url = "https://raw.githubusercontent.com/freebsd/freebsd-ports/42da4cdf2d9161fea8f7cdfc19aefda7707fadf4/audio/cdparanoia/files/patch-interface_low__interface.h";
      hash = "sha256-bXrcRFCbU7/7/N+J8VGKGSxIB1m8XwoAlc/KTnt9wN0=";
      extraPrefix = "";
      postFetch = ''
        sed -E -i -e 's/\<Linux\>/__linux__/g' $out
      '';
    })
    (fetchpatch {
      url = "https://raw.githubusercontent.com/freebsd/freebsd-ports/42da4cdf2d9161fea8f7cdfc19aefda7707fadf4/audio/cdparanoia/files/patch-interface_scan__devices.c";
      hash = "sha256-UD7SXeypF3bAqT7Y24UOrGZNaD8ZmpS2V7XQU+3VKXk=";
      extraPrefix = "";
      postFetch = ''
        sed -E -i -e 's/\<private\>/private_data/g' $out
        sed -E -i -e 's/\<Linux\>/__linux__/g' $out
      '';
    })
    (fetchpatch {
      url = "https://raw.githubusercontent.com/freebsd/freebsd-ports/42da4cdf2d9161fea8f7cdfc19aefda7707fadf4/audio/cdparanoia/files/patch-interface_cdda__interface.h";
      hash = "sha256-JL4qe4LwmNp2jQFqTvyRjc6bixGqYr6BZmqsYIY9xhw=";
      extraPrefix = "";
      postFetch = ''
        sed -E -i -e 's/\<Linux\>/__linux__/g' $out
      '';
    })
    (fetchpatch {
      url = "https://raw.githubusercontent.com/freebsd/freebsd-ports/42da4cdf2d9161fea8f7cdfc19aefda7707fadf4/audio/cdparanoia/files/patch-interface_common__interface.c";
      hash = "sha256-vw0oFM6w15YBaAK01FwVcSN+oztSfo5jL6OlGy0iWBg=";
      extraPrefix = "";
      postFetch = ''
        sed -E -i -e 's/\<Linux\>/__linux__/g' $out
      '';
    })
    (fetchpatch {
      url = "https://raw.githubusercontent.com/freebsd/freebsd-ports/42da4cdf2d9161fea8f7cdfc19aefda7707fadf4/audio/cdparanoia/files/patch-interface_cooked__interface.c";
      hash = "sha256-g39dhxb8+K9BIb2/5cmkQ9GYjg4gDjj6sv+dXx93kQ4=";
      extraPrefix = "";
      postFetch = ''
        sed -E -i -e 's/\<Linux\>/__linux__/g' $out
      '';
    })
    (fetchpatch {
      url = "https://raw.githubusercontent.com/freebsd/freebsd-ports/42da4cdf2d9161fea8f7cdfc19aefda7707fadf4/audio/cdparanoia/files/patch-interface_interface.c";
      hash = "sha256-LMWfbqLjbQM3L4H3orAxyyAHf1hVtFwfmZY8NmBLKzs=";
      extraPrefix = "";
      postFetch = ''
        sed -E -i -e 's/\<private\>/private_data/g' $out
        sed -E -i -e 's/\<Linux\>/__linux__/g' $out
      '';
    })
    (fetchpatch {
      url = "https://raw.githubusercontent.com/freebsd/freebsd-ports/42da4cdf2d9161fea8f7cdfc19aefda7707fadf4/audio/cdparanoia/files/patch-interface_scsi__interface.c";
      hash = "sha256-dx6YCWW8J0e455phaYDUMiOCvp4DsfINjSEiEfnHaNI=";
      extraPrefix = "";
      postFetch = ''
        sed -E -i -e 's/\<private\>/private_data/g' $out
        sed -E -i -e 's/\<Linux\>/__linux__/g' $out
      '';
    })
    (fetchpatch {
      url = "https://raw.githubusercontent.com/freebsd/freebsd-ports/42da4cdf2d9161fea8f7cdfc19aefda7707fadf4/audio/cdparanoia/files/patch-Makefile.in";
      hash = "sha256-Wje2d58xrSWHJNktQRHcNSbh5yh6vMtpgc/3G4D1vrI=";
      extraPrefix = "";
      postFetch = ''
        sed -E -i -e 's/\<Linux\>/__linux__/g' $out
      '';
    })
  ];

  nativeBuildInputs = [
    updateAutotoolsGnuConfigScriptsHook
    autoreconfHook
  ];

  env = {
    BSD_INSTALL_PROGRAM = "install";
    BSD_INSTALL_LIB = "install";
    NIX_CFLAGS_COMPILE = "-Wno-format-truncation -Wno-format-security";
  };

  hardeningDisable = [ "format" ];

  enableParallelBuilding = false;

  meta = {
    homepage = "https://xiph.org/paranoia";
    description = "Tool and library for reading digital audio from CDs";
    license = with lib.licenses; [
      gpl2Plus
      lgpl21Plus
    ];
    platforms = lib.platforms.unix;
  };
})
