{
  lib,
  stdenv,
  fetchFromGitHub,
  autoreconfHook,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "libcpuid";
  version = "0.8.2";

  src = fetchFromGitHub {
    owner = "anrieff";
    repo = "libcpuid";
    tag = "v${finalAttrs.version}";
    hash = "sha256-RURoeuiElYT+abMsSjV8Wpn923CvSJW5/BSoUBPEHGA=";
  };

  nativeBuildInputs = [ autoreconfHook ];

  meta = {
    homepage = "https://libcpuid.sourceforge.net/";
    description = "Small C library for x86 CPU detection and feature extraction";
    mainProgram = "cpuid_tool";
    changelog = "https://raw.githubusercontent.com/anrieff/libcpuid/master/ChangeLog";
    license = lib.licenses.bsd2;
    platforms = lib.platforms.x86;
  };
})
