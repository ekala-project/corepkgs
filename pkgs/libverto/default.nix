{
  lib,
  stdenv,
  fetchFromGitHub,
  autoreconfHook,
  glib,
  libev,
  libevent,
  pkg-config,
}:

stdenv.mkDerivation rec {
  pname = "libverto";
  version = "0.3.2";

  src = fetchFromGitHub {
    owner = "latchset";
    repo = "libverto";
    rev = version;
    hash = "sha256-csoJ0WdKyrza8kBSMKoaItKvcbijI6Wl8nWCbywPScQ=";
  };

  nativeBuildInputs = [
    autoreconfHook
    pkg-config
  ];

  buildInputs = [
    glib
    libev
    libevent
  ];

  meta = {
    homepage = "https://github.com/latchset/libverto";
    description = "Asynchronous event loop abstraction library";
    license = lib.licenses.mit;
    maintainers = [ ];
    platforms = lib.platforms.unix;
  };
}
