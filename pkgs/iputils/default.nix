{
  lib,
  stdenv,
  fetchFromGitHub,
  meson,
  ninja,
  pkg-config,
  gettext,
  libxslt,
  docbook-xsl-ns,
  libcap,
  libidn2,
  iproute2,
  libapparmor,
}:

let
  apparmorRulesFromClosure = libapparmor.passthru.apparmorRulesFromClosure;
in

stdenv.mkDerivation (finalAttrs: {
  pname = "iputils";
  version = "20250605";

  src = fetchFromGitHub {
    owner = finalAttrs.pname;
    repo = finalAttrs.pname;
    rev = finalAttrs.version;
    hash = "sha256-AJgNPIE90kALu4ihANELr9Dh28LhJ4camLksOIRV8Xo=";
  };

  outputs = [
    "out"
    "apparmor"
  ];

  # We don't have the required permissions inside the build sandbox:
  # /build/source/build/ping/ping: socket: Operation not permitted
  doCheck = false;

  mesonFlags = [
    "-DNO_SETCAP_OR_SUID=true"
    "-Dsystemdunitdir=etc/systemd/system"
    "-DINSTALL_SYSTEMD_UNITS=true"
    "-DSKIP_TESTS=${lib.boolToString (!finalAttrs.doCheck)}"
  ]
  # Disable idn usage w/musl (https://github.com/iputils/iputils/pull/111):
  ++ lib.optional stdenv.hostPlatform.isMusl "-DUSE_IDN=false";

  nativeBuildInputs = [
    meson
    meson.configurePhaseHook
    ninja
    pkg-config
    gettext
    libxslt.bin
    docbook-xsl-ns
  ];
  buildInputs = [ libcap ] ++ lib.optional (!stdenv.hostPlatform.isMusl) libidn2;
  nativeCheckInputs = [ iproute2 ];

  postInstall = ''
    mkdir $apparmor
    cat >$apparmor/bin.ping <<EOF
    include <tunables/global>
    $out/bin/ping {
      include <abstractions/base>
      include <abstractions/consoles>
      include <abstractions/nameservice>
      include "${
        apparmorRulesFromClosure { name = "ping"; } (
          [ libcap ] ++ lib.optional (!stdenv.hostPlatform.isMusl) libidn2
        )
      }"
      include <local/bin.ping>
      capability net_raw,
      network inet raw,
      network inet6 raw,
      mr $out/bin/ping,
      r $out/share/locale/**,
      r @{PROC}/@{pid}/environ,
    }
    EOF
  '';

  passthru.tests.unit = finalAttrs.finalPackage.overrideAttrs { doCheck = true; };

  meta = {
    homepage = "https://github.com/iputils/iputils";
    changelog = "https://github.com/iputils/iputils/releases/tag/${finalAttrs.version}";
    description = "Set of small useful utilities for Linux networking";
    longDescription = ''
      A set of small useful utilities for Linux networking including:

      - arping: send ARP REQUEST to a neighbour host
      - clockdiff: measure clock difference between hosts
      - ping: send ICMP ECHO_REQUEST to network hosts
      - tracepath: traces path to a network host discovering MTU along this path
    '';
    license = with lib.licenses; [
      gpl2Plus
      bsd3
    ];
    platforms = lib.platforms.linux;
  };
})
