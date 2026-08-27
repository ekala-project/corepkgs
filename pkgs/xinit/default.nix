{
  lib,
  buildXorgPackage,
  buildPackages,
  stdenv,
  pkg-config,
  fetchurl,
  libx11,
  libxau,
  xorgproto,
  xorg-server,
  bootstrap_cmds ? null,
}:

let
  isDarwin = stdenv.hostPlatform.isDarwin;
in

buildXorgPackage (finalAttrs: {
  pname = "xinit";
  version = "1.4.4";
  src = fetchurl {
    url = "mirror://xorg/individual/app/xinit-1.4.4.tar.xz";
    sha256 = "1ygymifhg500sx1ybk8x4d1zn4g4ywvlnyvqwcf9hzsc2rx7r920";
  };
  nativeBuildInputs = [
    pkg-config
  ]
  ++ lib.optional isDarwin bootstrap_cmds;

  depsBuildBuild = [ buildPackages.stdenv.cc ];

  buildInputs = [
    libx11
    libxau
    xorgproto
  ];

  configureFlags = [
    "--with-xserver=${xorg-server.out}/bin/X"
  ]
  ++ lib.optionals isDarwin [
    "--with-bundle-id-prefix=org.nixos.xquartz"
    "--with-launchdaemons-dir=\${out}/LaunchDaemons"
    "--with-launchagents-dir=\${out}/LaunchAgents"
  ];

  postPatch = ''
    substituteInPlace Makefile.in --replace "PROGCPPDEFS =" "PROGCPPDEFS = -Dlinux=linux -Dunix=unix"
  '';

  propagatedBuildInputs =
    # TODO(corepkgs): xauth is not available yet
    lib.optionals isDarwin [
      libx11
      xorgproto
    ];

  postFixup = ''
    sed -i $out/bin/startx \
      -e '/^sysserverrc=/ s:=.*:=/etc/X11/xinit/xserverrc:' \
      -e '/^sysclientrc=/ s:=.*:=/etc/X11/xinit/xinitrc:'
  '';

  meta.mainProgram = "xinit";
  meta.identifiers.cpeParts.vendor = "x.org";
})
