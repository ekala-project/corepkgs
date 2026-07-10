{
  lib,
  stdenv,
  fetchFromGitHub,
  autoreconfHook,
  pkg-config,
  libite,
  libuev,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "finit";
  version = "4.17";

  src = fetchFromGitHub {
    owner = "troglobit";
    repo = "finit";
    tag = finalAttrs.version;
    hash = "sha256-sH4xZNMEuIS+r6rVQAKnsHtSyTe2B6gdYcmH9J8eSZ0=";
  };

  postPatch = ''
    substituteInPlace plugins/modprobe.c --replace-fail \
      '"/lib/modules"' '"/run/booted-system/kernel-modules/lib/modules"'
  '';

  strictDeps = true;

  nativeBuildInputs = [
    autoreconfHook
    pkg-config
  ];

  buildInputs = [
    libite
    libuev
  ];

  outputs = [
    "out"
    "dev"
    "doc"
  ];

  configureFlags = [
    "--sysconfdir=/etc"
    "--localstatedir=/var"

    # tweak default plugin list
    "--enable-modules-load-plugin=yes"
    "--enable-hotplug-plugin=no"

    # minimal replacement for systemd notification library
    "--with-libsystemd"

    # monitor kernel events, like ac power status
    "--with-keventd"
  ];

  env.NIX_CFLAGS_COMPILE = toString [
    "-D_PATH_LOGIN=\"/run/current-system/sw/bin/login\""
    "-DSYSCTL_PATH=\"/run/current-system/sw/bin/sysctl\""
  ];

  meta = {
    description = "Fast init for Linux";
    mainProgram = "initctl";
    homepage = "https://troglobit.com/projects/finit/";
    license = lib.licenses.mit;
    platforms = lib.platforms.unix;
  };
})
