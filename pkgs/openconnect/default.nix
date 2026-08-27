{
  lib,
  stdenv,
  fetchFromGitLab,
  pkg-config,
  gnutls,
  p11-kit,
  gmp,
  libxml2,
  zlib,
  pcsclite,
  autoreconfHook,
}:

stdenv.mkDerivation {
  pname = "openconnect";
  version = "9.12-unstable-2025-11-03";

  src = fetchFromGitLab {
    owner = "openconnect";
    repo = "openconnect";
    rev = "0dcdff87db65daf692dc323732831391d595d98d";
    hash = "sha256-AvowUEDkXvR+QkhJbZU759fZjIqj/mO8HjP2Ka3lH1U=";
  };

  outputs = [
    "out"
    "dev"
  ];

  configureFlags = [
    # TODO(corepkgs): Port vpnc-scripts and set proper path
    "--with-vpnc-script=/etc/vpnc/vpnc-script"
    "--disable-nls"
    "--without-openssl-version-check"
    "--without-stoken"
  ];

  nativeBuildInputs = [
    pkg-config
    autoreconfHook
  ];

  buildInputs = [
    gmp
    libxml2
    zlib
    gnutls
    # TODO(corepkgs): Port stoken for TOTP support
  ]
  ++ lib.optionals stdenv.hostPlatform.isLinux [
    p11-kit
    pcsclite
  ];

  meta = {
    description = "VPN Client for Cisco's AnyConnect SSL VPN";
    homepage = "https://www.infradead.org/openconnect/";
    license = lib.licenses.lgpl21Only;
    platforms = lib.platforms.unix;
    mainProgram = "openconnect";
    identifiers.cpeParts.vendor = "infradead";
  };
}
