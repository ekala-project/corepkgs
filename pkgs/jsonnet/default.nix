# jsonnet — Data templating language
{
  stdenv,
  lib,
  cmake,
  fetchFromGitHub,
  fetchpatch,
  gtest,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "jsonnet";
  version = "0.21.0";

  src = fetchFromGitHub {
    rev = "v${finalAttrs.version}";
    owner = "google";
    repo = "jsonnet";
    sha256 = "sha256-QHp0DOu/pqcgN7di219cHzfFb7fWtdGGE6J1ZXgbOGQ=";
  };

  patches = [
    (fetchpatch {
      url = "https://github.com/google/jsonnet/commit/6c87c1b0e1e18d25898be071c1b231e264f05a8c.patch";
      hash = "sha256-KprhMKwUCpvLiMT/grfqZ8Vt9rbosIizQgNMStuV8/U=";
    })
  ];

  nativeBuildInputs = [ cmake ];
  buildInputs = [ gtest ];

  cmakeFlags = [
    "-DUSE_SYSTEM_GTEST=ON"
    "-DBUILD_STATIC_LIBS=${if stdenv.hostPlatform.isStatic then "ON" else "OFF"}"
  ]
  ++ lib.optionals (!stdenv.hostPlatform.isDarwin) [
    "-DBUILD_SHARED_BINARIES=${if stdenv.hostPlatform.isStatic then "OFF" else "ON"}"
  ];

  enableParallelBuilding = true;

  meta = {
    description = "Purely-functional configuration language that helps you define JSON data";
    homepage = "https://github.com/google/jsonnet";
    license = lib.licenses.asl20;
    platforms = lib.platforms.unix;
  };
})
