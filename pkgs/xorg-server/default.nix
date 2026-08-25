{
  lib,
  buildXorgPackage,
  buildPackages,
  stdenv,
  pkg-config,
  fetchurl,
  fetchpatch,
  # Core X deps
  xorgproto,
  openssl,
  libx11,
  libxau,
  libxcb,
  xcbutil,
  xcbutilwm,
  xcbutilimage,
  xcbutilkeysyms,
  xcbutilrenderutil,
  libxdmcp,
  libXfixes,
  libxkbfile,
  # Override deps
  xtrans,
  libxcvt,
  dbus,
  libGL,
  libGLU,
  libxext,
  libXfont2 ? null,
  libepoxy,
  libunwind,
  libxshmfence,
  pixman,
  zlib,
  libdrm,
  libgbm,
  mesa-gl-headers,
  dri-pkgconfig-stub,
  udev,
  libpciaccess,
  # xkb
  xkbcomp,
  xkeyboard-config,
  # Darwin
  autoreconfHook,
  automake,
  autoconf,
  mesa,
  bootstrap_cmds ? null,
  # clangStdenv,  # TODO(corepkgs): support darwin
}:

let
  isDarwin = stdenv.hostPlatform.isDarwin;
in

buildXorgPackage (finalAttrs: {
  pname = "xorg-server";
  version = "21.1.20";
  src = fetchurl {
    url = "mirror://xorg/individual/xserver/xorg-server-21.1.20.tar.xz";
    sha256 = "sha256-dpW8YYJLOoG2utL3iwVADKAVAD3kAtGzIhFxBbcC6Tc=";
  };

  outputs = [
    "out"
    "dev"
  ];

  postPatch = ''
    for i in dri3/*.c
    do
      sed -i -e "s|#include <drm_fourcc.h>|#include <libdrm/drm_fourcc.h>|" $i
    done
  '';

  nativeBuildInputs = [ pkg-config ];

  buildInputs = [
    xorgproto
    openssl
    libx11
    libxau
    libxcb
    xcbutil
    xcbutilwm
    xcbutilimage
    xcbutilkeysyms
    xcbutilrenderutil
    libxdmcp
    libXfixes
    libxkbfile
    xtrans
    libxcvt
  ]
  ++ lib.optional (libdrm != null) libdrm.dev
  ++ lib.optionals (!isDarwin) [
    libdrm
    libgbm
    mesa-gl-headers
    dri-pkgconfig-stub
  ]
  ++ lib.optionals isDarwin [
    bootstrap_cmds
    automake
    autoconf
    mesa
  ];

  propagatedBuildInputs = [
    dbus
    libGL
    libGLU
    libxext
    libepoxy
    libunwind
    libxshmfence
    pixman
    xorgproto
    zlib
  ]
  ++ lib.optionals (!isDarwin) [
    libpciaccess
  ]
  ++ lib.optionals stdenv.hostPlatform.isLinux [
    udev
  ]
  ++ lib.optional (libXfont2 != null) libXfont2;

  depsBuildBuild = lib.optionals (!isDarwin) [ buildPackages.stdenv.cc ];

  patches =
    if (!isDarwin) then
      [
        ../xorg/dont-create-logdir-during-build.patch
      ]
    else
      [
        (fetchpatch {
          url = "https://github.com/XQuartz/xorg-server/commit/e88fd6d785d5be477d5598e70d105ffb804771aa.patch";
          sha256 = "1q0a30m1qj6ai924afz490xhack7rg4q3iig2gxsjjh98snikr1k";
          name = "use-cppflags-not-cflags.patch";
        })
        (fetchpatch {
          url = "https://github.com/XQuartz/xorg-server/commit/75ee9649bcfe937ac08e03e82fd45d9e18110ef4.patch";
          sha256 = "1vlfylm011y00j8mig9zy6gk9bw2b4ilw2qlsc6la49zi3k0i9fg";
          name = "use-old-mitrapezoids-and-mitriangles-routines.patch";
        })
        (fetchpatch {
          url = "https://github.com/XQuartz/xorg-server/commit/c58f47415be79a6564a9b1b2a62c2bf866141e73.patch";
          sha256 = "19sisqzw8x2ml4lfrwfvavc2jfyq2bj5xcf83z89jdxg8g1gdd1i";
          name = "revert-fb-changes-1.patch";
        })
        (fetchpatch {
          url = "https://github.com/XQuartz/xorg-server/commit/56e6f1f099d2821e5002b9b05b715e7b251c0c97.patch";
          sha256 = "0zm9g0g1jvy79sgkvy0rjm6ywrdba2xjd1nsnjbxjccckbr6i396";
          name = "revert-fb-changes-2.patch";
        })
        ../xorg/darwin/bundle_main.patch
        ../xorg/darwin/stub.patch
      ];

  prePatch = lib.optionalString stdenv.hostPlatform.isMusl ''
    export CFLAGS+=" -D__uid_t=uid_t -D__gid_t=gid_t"
  '';

  configureFlags =
    if (!isDarwin) then
      [
        "--enable-kdrive"
        "--enable-xephyr"
        "--enable-xcsecurity"
        "--with-default-font-path="
        "--with-xkb-bin-directory=${xkbcomp}/bin"
        "--with-xkb-path=${xkeyboard-config}/share/X11/xkb"
        "--with-xkb-output=$out/share/X11/xkb/compiled"
        "--with-log-dir=/var/log"
        "--enable-glamor"
        "--with-os-name=Nix"
      ]
      ++ lib.optionals stdenv.hostPlatform.isMusl [
        "--disable-tls"
      ]
    else
      [
        "CPPFLAGS=-I${../xorg/darwin/dri}"
        "--disable-libunwind"
        "--disable-glamor"
        "--with-default-font-path="
        "--with-apple-application-name=XQuartz"
        "--with-apple-applications-dir=\${out}/Applications"
        "--with-bundle-id-prefix=org.nixos.xquartz"
        "--with-sha1=CommonCrypto"
        "--with-xkb-bin-directory=${xkbcomp}/bin"
        "--with-xkb-path=${xkeyboard-config}/share/X11/xkb"
        "--with-xkb-output=$out/share/X11/xkb/compiled"
        "--without-dtrace"
      ];

  env.NIX_CFLAGS_COMPILE = lib.optionalString (!isDarwin) (toString [
    "-Wno-error=array-bounds"
  ]);

  preConfigure = lib.optionalString isDarwin ''
    mkdir -p $out/Applications
    export NIX_CFLAGS_COMPILE="$NIX_CFLAGS_COMPILE -Wno-error"
  '';

  postInstall =
    if (!isDarwin) then
      ''
        rm -fr $out/share/X11/xkb/compiled
        (
          cd "$dev"
          for f in include/xorg/*.h; do
            sed "1i#line 1 \"${finalAttrs.pname}-${finalAttrs.version}/$f\"" -i "$f"
          done
        )
      ''
    else
      ''
        rm -fr $out/share/X11/xkb/compiled
      '';
  # TODO(corepkgs): darwin postInstall needs darwinOtherX binary merging

  passthru = {
    inherit (finalAttrs) version;
  };

  meta = {
    mainProgram = "X";
    pkgConfigModules = [ "xorg-server" ];
  };
})
