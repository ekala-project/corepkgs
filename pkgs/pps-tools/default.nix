{
  lib,
  stdenv,
  fetchFromGitHub,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "pps-tools";
  version = "1.0.3";

  src = fetchFromGitHub {
    owner = "redlab-i";
    repo = "pps-tools";
    rev = "v${finalAttrs.version}";
    hash = "sha256-eLLFHrCgOQzOtVxlAsZ5X91KK+vZiKMGL7zbQFiIZtI=";
  };

  outputs = [
    "out"
    "dev"
  ];

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin $dev/include
    mkdir -p $out/{usr/bin,usr/include/sys}
    make install DESTDIR=$out
    mv $out/usr/bin/* $out/bin
    mv $out/usr/include/* $dev/include/
    rm -rf $out/usr/
    runHook postInstall
  '';

  meta = {
    description = "User-space tools for LinuxPPS";
    homepage = "http://linuxpps.org/";
    license = lib.licenses.gpl2Plus;
    platforms = lib.platforms.linux;
  };
})
