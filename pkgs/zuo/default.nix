{
  lib,
  stdenv,
  fetchFromGitHub,
  autoreconfHook,
  buildPackages,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "zuo";
  version = "1.16";

  src = fetchFromGitHub {
    owner = "racket";
    repo = "zuo";
    tag = "v${finalAttrs.version}";
    hash = "sha256-VxF6NfnACsEvrE3GNxuQ4sSh34bh4pkKEEKsxEWy2F0=";
  };

  depsBuildBuild = [ buildPackages.stdenv.cc ];
  nativeBuildInputs = [ autoreconfHook ];

  configureFlags = [
    "CC_FOR_BUILD=cc"
  ];

  meta = {
    description = "Tiny Racket for Scripting";
    mainProgram = "zuo";
    homepage = "https://github.com/racket/zuo";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
  };
})
