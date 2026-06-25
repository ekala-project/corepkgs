{
  lib,
  stdenv,
  fetchFromGitHub,
  bash,
  bison,
  flex,
  which,
  perl,
}:

let
  version = "3.6.2";
  tag = "V" + lib.replaceStrings [ "." ] [ "-" ] version;
in
stdenv.mkDerivation {
  pname = "lm-sensors";
  inherit version;

  src = fetchFromGitHub {
    owner = "hramrach";
    repo = "lm-sensors";
    inherit tag;
    hash = "sha256-EmS9H3TQac6bHs2G8t1C2cQNAjN13zPoKDysny6aTFw=";
  };

  outputs = [
    "bin"
    "out"
    "dev"
    "man"
    "doc"
  ];

  postPatch = ''
    substituteInPlace lib/init.c \
      --replace-fail 'ETCDIR "/sensors.d"' '"/etc/sensors.d"'
  '';

  nativeBuildInputs = [
    bison
    flex
    which
  ];

  buildInputs = [
    bash
    perl
  ];

  makeFlags = [
    "PREFIX=${placeholder "out"}"
    "BINDIR=${placeholder "bin"}/bin"
    "SBINDIR=${placeholder "bin"}/bin"
    "INCLUDEDIR=${placeholder "dev"}/include"
    "MANDIR=${placeholder "man"}/share/man"
    "ETCDIR=${placeholder "out"}/etc"
    "BUILD_SHARED_LIB=${if stdenv.hostPlatform.isStatic then "0" else "1"}"
    "BUILD_STATIC_LIB=${if stdenv.hostPlatform.isStatic then "1" else "0"}"
    "CC=${stdenv.cc.targetPrefix}cc"
    "AR=${stdenv.cc.targetPrefix}ar"
  ];

  enableParallelBuilding = true;

  postInstall = ''
    mkdir -p $doc/share/doc/lm_sensors
    cp -r configs doc/* $doc/share/doc/lm_sensors
  '';

  meta = {
    homepage = "https://hwmon.wiki.kernel.org/lm_sensors";
    description = "Tools for reading hardware sensors";
    license = with lib.licenses; [
      lgpl21Plus
      gpl2Plus
    ];
    maintainers = [ ];
    platforms = lib.platforms.linux;
    mainProgram = "sensors";
  };
}
