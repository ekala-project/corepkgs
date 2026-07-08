{
  lib,
  stdenv,
  fetchFromGitHub,
  autoreconfHook,
  pkg-config,
  swig,
  testers,
  nix-update-script,
  runUnitTests,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "libcap-ng";
  version = "0.9.3";

  src = fetchFromGitHub {
    owner = "stevegrubb";
    repo = "libcap-ng";
    tag = "v${finalAttrs.version}";
    hash = "sha256-anuPOBWp4Hlpo+m6kYlSd2v7H3P7LQ9brZdq1lo7Po4=";
  };

  # NEWS needs to exist or else the build fails
  postPatch = ''
    touch NEWS
  '';

  strictDeps = true;
  enableParallelBuilding = true;

  nativeBuildInputs = [
    autoreconfHook
    pkg-config
    swig
  ];

  outputs = [
    "out"
    "dev"
    "man"
  ];

  configureFlags = [
    "--without-python"
  ];

  passthru = {
    updateScript = nix-update-script { };
    tests = {
      unittests = runUnitTests finalAttrs.finalPackage;
      pkg-config = testers.testMetaPkgConfig finalAttrs.finalPackage;
      pkg-config-install = testers.pkg-config.testInstall finalAttrs.finalPackage { };
    };
  };

  meta = {
    changelog = "https://people.redhat.com/sgrubb/libcap-ng/ChangeLog";
    description = "Library for working with POSIX capabilities";
    homepage = "https://people.redhat.com/sgrubb/libcap-ng/";
    pkgConfigModules = [ "libcap-ng" ];
    platforms = lib.platforms.linux;
    license = lib.licenses.lgpl21;
  };
})
