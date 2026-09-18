{
  lib,
  stdenv,
  fetchurl,
  fetchpatch,
  autoreconfHook,
  pkg-config,
  help2man,
  python3,
  linuxHeaders,

  alsa-lib,
  libxslt,
  systemd,
  libusb-compat-0_1,
  libftdi1,
  libice,
  libsm,
  libx11,
}:

let
  pythonEnv = python3.pythonOnBuildForHost.withPackages (
    p: with p; [
      pyyaml
      setuptools
    ]
  );
in
stdenv.mkDerivation (finalAttrs: {
  pname = "lirc";
  version = "0.10.2";

  src = fetchurl {
    url = "mirror://sourceforge/lirc/lirc-${finalAttrs.version}.tar.bz2";
    sha256 = "sha256-PUTsgnSIHPJi8WCAVkHwgn/8wgreDYXn5vO5Dg09Iio=";
  };

  patches = [
    (fetchpatch {
      url = "https://sourceforge.net/p/lirc/tickets/339/attachment/0001-Fix-Python-bindings.patch";
      sha256 = "088a39x8c1qd81qwvbiqd6crb2lk777wmrs8rdh1ga06lglyvbly";
    })

    ./linux-headers-5.18.patch
    ./ubuntu.diff
    ./pythonpath.patch
  ];

  postPatch = ''
    patchShebangs .

    substituteInPlace python-pkg/lirc/database.py \
      --replace-fail 'yaml.load(' 'yaml.safe_load('

    substituteInPlace systemd/*.service \
      --replace-fail "ExecStart=/usr/" "ExecStart=''${!outputBin}/"
  '';

  preConfigure = ''
    export PKGCONFIG="$PKG_CONFIG"
  '';

  strictDeps = true;

  nativeBuildInputs = [
    autoreconfHook
    help2man
    libxslt
    pythonEnv
    pkg-config
  ];

  buildInputs = [
    alsa-lib
    systemd
    libusb-compat-0_1
    libftdi1
    libice
    libsm
    libx11
  ];

  env.DEVINPUT_HEADER = "${linuxHeaders}/include/linux/input-event-codes.h";

  configureFlags = [
    "--sysconfdir=/etc"
    "--localstatedir=/var"
    "--with-systemdsystemunitdir=$(out)/lib/systemd/system"
    "--enable-uinput"
    "--enable-devinput"
    "--with-lockdir=/run/lirc/lock"
    "PYTHON=${pythonEnv.interpreter}"
  ];

  installFlags = [
    "sysconfdir=$out/etc"
    "localstatedir=$TMPDIR"
  ];

  outputs = [
    "out"
    "man"
    "doc"
    "dev"
    "lib"
  ];

  postFixup = ''
    moveToOutput "${python3.sitePackages}" "$out"
    rm $out/bin/lirc-setup
    ln -s $out/${python3.sitePackages}/lirc-setup/lirc-setup $out/bin/lirc-setup
  '';

  dontCheckForBrokenSymlinks = true;

  meta = {
    description = "Allows to receive and send infrared signals";
    homepage = "https://www.lirc.org/";
    license = lib.licenses.gpl2;
    platforms = lib.platforms.linux;
  };
})
