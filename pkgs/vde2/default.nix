{
  lib,
  stdenv,
  fetchFromGitHub,
  autoreconfHook,
  libpcap,
  wolfssl,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "vde2";
  version = "2.3.3";

  src = fetchFromGitHub {
    owner = "virtualsquare";
    repo = "vde-2";
    rev = "v${finalAttrs.version}";
    hash = "sha256-Yf6QB7j5lYld2XtqhYspK4037lTtimoFc7nCavCP+mU=";
  };

  # Fix build with gcc15
  # https://github.com/virtualsquare/vde-2/commit/fedcb99c5f44c397f459ed0951a8fba4f4effb73
  env.NIX_CFLAGS_COMPILE = "-std=gnu17";

  nativeBuildInputs = [ autoreconfHook ];

  buildInputs = [
    libpcap
    wolfssl
  ];

  meta = {
    homepage = "https://github.com/virtualsquare/vde-2";
    description = "Virtual Distributed Ethernet, an Ethernet compliant virtual network";
    platforms = lib.platforms.unix;
    license = lib.licenses.gpl2Plus;
  };
})
