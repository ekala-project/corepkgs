{
  lib,
  stdenv,
  fetchFromGitHub,
  pkg-config,
  autoreconfHook,
  openssl,
  perl,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "libtpms";
  version = "0.10.1";

  src = fetchFromGitHub {
    owner = "stefanberger";
    repo = "libtpms";
    rev = "v${finalAttrs.version}";
    sha256 = "sha256-uj06cAhepTOFxSeiBY/UVP/rtBQHLvrODe4ljU6ALOE=";
  };

  hardeningDisable = [ "strictflexarrays3" ];

  nativeBuildInputs = [
    autoreconfHook
    pkg-config
    perl # needed for pod2man
  ];
  buildInputs = [ openssl ];

  outputs = [
    "out"
    "man"
    "dev"
  ];

  enableParallelBuilding = true;

  configureFlags = [
    "--with-openssl"
    "--with-tpm2"
  ];

  doCheck = false;

  passthru.tests.unit = finalAttrs.finalPackage.overrideAttrs { doCheck = true; };

  meta = {
    description = "Library for software emulation of a Trusted Platform Module (TPM 1.2 and TPM 2.0)";
    homepage = "https://github.com/stefanberger/libtpms";
    license = lib.licenses.bsd3;
  };
})
