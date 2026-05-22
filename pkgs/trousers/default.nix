{
  lib,
  stdenv,
  fetchurl,
  openssl,
  pkg-config,
  autoreconfHook,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "trousers";
  version = "0.3.15";

  src = fetchurl {
    url = "mirror://sourceforge/trousers/trousers/${finalAttrs.version}/${finalAttrs.pname}-${finalAttrs.version}.tar.gz";
    sha256 = "0zy7r9cnr2gvwr2fb1q4fc5xnvx405ymcbrdv7qsqwl3a4zfjnqy";
  };

  nativeBuildInputs = [
    pkg-config
    autoreconfHook
  ];
  buildInputs = [ openssl ];

  patches = [ ./allow-non-tss-config-file-owner.patch ];

  configureFlags = [ "--disable-usercheck" ];

  env.NIX_CFLAGS_COMPILE = toString [ "-DALLOW_NON_TSS_CONFIG_FILE" ];
  enableParallelBuilding = true;

  doCheck = false;

  passthru.tests.unit = finalAttrs.finalPackage.overrideAttrs { doCheck = true; };

  meta = {
    description = "Trusted computing software stack";
    mainProgram = "tcsd";
    homepage = "https://trousers.sourceforge.net/";
    license = lib.licenses.bsd3;
    platforms = lib.platforms.linux;
  };
})
