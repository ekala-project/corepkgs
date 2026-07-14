{
  lib,
  stdenv,
  fetchFromGitHub,
  autoreconfHook,
  perl,
  readline,
  testers,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "rlwrap";
  version = "0.48";

  src = fetchFromGitHub {
    owner = "hanslub42";
    repo = "rlwrap";
    tag = "v${finalAttrs.version}";
    hash = "sha256-Szgyjt/KRFEZMu6JX4Ulm2guTMwh9ejzjlfpkITWOI4=";
  };

  nativeBuildInputs = [
    autoreconfHook
    perl
  ];

  buildInputs = [ readline ];

  # The .rb files (red-black tree definitions, not Ruby) have far-future
  # timestamps, causing make to try regenerating .c files using rbgen
  # (from libredblack) which isn't available. Ensure .c files are newer.
  postPatch = ''
    touch src/*.rb
    touch src/*.c
  '';

  configureFlags = [ "--without-libptytty" ];

  env.NIX_CFLAGS_COMPILE = lib.optionalString stdenv.hostPlatform.isDarwin "-Wno-error=implicit-function-declaration";

  passthru.tests = {
    version = testers.testVersion {
      package = finalAttrs.finalPackage;
      command = "rlwrap --version";
    };
  };

  meta = with lib; {
    description = "Readline wrapper for console programs";
    homepage = "https://github.com/hanslub42/rlwrap";
    changelog = "https://github.com/hanslub42/rlwrap/raw/refs/tags/v${finalAttrs.version}/NEWS";
    license = licenses.gpl2Plus;
    platforms = platforms.unix;
    maintainers = [ ];
    mainProgram = "rlwrap";
  };
})
