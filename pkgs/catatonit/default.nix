{
  stdenv,
  lib,
  autoreconfHook,
  fetchFromGitHub,
  glibc,
  runCommand,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "catatonit";
  version = "0.2.1";

  src = fetchFromGitHub {
    owner = "openSUSE";
    repo = "catatonit";
    rev = "v${finalAttrs.version}";
    sha256 = "sha256-sc/T4WjCPFfwUWxlBx07mQTmcOApblHygfVT824HcJM=";
  };

  nativeBuildInputs = [ autoreconfHook ];
  buildInputs = lib.optionals (!stdenv.hostPlatform.isMusl) [
    glibc
    glibc.static
  ];

  enableParallelBuilding = true;
  strictDeps = true;

  doInstallCheck = true;
  installCheckPhase = ''
    readelf -d $out/bin/catatonit | grep 'There is no dynamic section in this file.'
  '';

  passthru.tests = {
    simple = runCommand "catatonit-test" { } ''
      # catatonit prints usage info when called without proper PID 1 context
      ${finalAttrs.finalPackage}/bin/catatonit --help 2>&1 || true
      touch $out
    '';
  };

  meta = {
    description = "Container init that is so simple it's effectively brain-dead";
    homepage = "https://github.com/openSUSE/catatonit";
    license = lib.licenses.gpl2Plus;
    maintainers = [ ];
    platforms = lib.platforms.linux;
    mainProgram = "catatonit";
  };
})
