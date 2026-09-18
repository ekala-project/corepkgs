{
  lib,
  stdenv,
  fetchFromGitHub,
  autoreconfHook,
  libogg,
  libvorbis,
  pkg-config,
  perl,
  validatePkgConfig,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "libtheora";
  version = "1.2.0";

  src = fetchFromGitHub {
    owner = "xiph";
    repo = "theora";
    tag = "v${finalAttrs.version}";
    hash = "sha256-kzZh4V6wZX9MetDutuqjRenmdpy4PHaRU9MgtIwPpiU=";
  };

  configureFlags = [ "--disable-examples" ];

  outputs = [
    "out"
    "dev"
  ];

  postPatch = lib.optionalString stdenv.hostPlatform.isAarch32 ''
    patchShebangs lib/arm/arm2gnu.pl
  '';

  nativeBuildInputs = [
    autoreconfHook
    pkg-config
    validatePkgConfig
  ]
  ++ lib.optionals stdenv.hostPlatform.isAarch32 [
    perl
  ];

  propagatedBuildInputs = [
    libogg
    libvorbis
  ];

  strictDeps = true;

  meta = {
    description = "Library for Theora, a free and open video compression format";
    homepage = "https://www.theora.org/";
    license = lib.licenses.bsd3;
    platforms = lib.platforms.unix;
  };
})
