{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
  openssl,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "srt";
  version = "1.5.5";

  src = fetchFromGitHub {
    owner = "Haivision";
    repo = "srt";
    rev = "v${finalAttrs.version}";
    sha256 = "sha256-hOkLlmtF9dKqXZTjAeBntkkg5WsmsZN6DKhyakoIF1k=";
  };

  nativeBuildInputs = [
    cmake
    cmake.configurePhaseHook
  ];

  buildInputs = [ openssl ];

  cmakeFlags = [
    "-DCMAKE_INSTALL_INCLUDEDIR=include"
    "-DENABLE_SHARED=${if stdenv.hostPlatform.isStatic then "OFF" else "ON"}"
    "-UCMAKE_INSTALL_LIBDIR"
  ];

  meta = {
    description = "Secure, Reliable, Transport";
    homepage = "https://github.com/Haivision/srt";
    license = lib.licenses.mpl20;
    platforms = lib.platforms.all;
  };
})
