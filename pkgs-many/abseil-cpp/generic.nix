{
  version,
  src-hash,
  packageOlder,
  ...
}:

{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
  gtest,
  fetchpatch,
  static ? stdenv.hostPlatform.isStatic,
  cxxStandard ? null,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "abseil-cpp";
  inherit version;

  src = fetchFromGitHub {
    owner = "abseil";
    repo = "abseil-cpp";
    tag = finalAttrs.version;
    hash = src-hash;
  };

  cmakeFlags = [
    (lib.cmakeBool "ABSL_BUILD_TEST_HELPERS" true)
    (lib.cmakeBool "ABSL_USE_EXTERNAL_GOOGLETEST" true)
    (lib.cmakeBool "BUILD_SHARED_LIBS" (!static))
  ]
  ++ lib.optionals (cxxStandard != null) [
    (lib.cmakeFeature "CMAKE_CXX_STANDARD" cxxStandard)
  ];

  patches = lib.optionals (packageOlder "20220000") [
    # Use CMAKE_INSTALL_FULL_{LIBDIR,INCLUDEDIR}
    # https://github.com/abseil/abseil-cpp/pull/963
    (fetchpatch {
      url = "https://github.com/abseil/abseil-cpp/commit/5bfa70c75e621c5d5ec095c8c4c0c050dcb2957e.patch";
      sha256 = "0nhjxqfxpi2pkfinnqvd5m4npf9l1kg39mjx9l3087ajhadaywl5";
    })

    # Bacport gcc-13 fix:
    #   https://github.com/abseil/abseil-cpp/pull/1187
    (fetchpatch {
      name = "gcc-13.patch";
      url = "https://github.com/abseil/abseil-cpp/commit/36a4b073f1e7e02ed7d1ac140767e36f82f09b7c.patch";
      hash = "sha256-aA7mwGEtv/cQINcawjkukmCvfNuqwUeDFssSiNKPdgg=";
    })

  ];
  strictDeps = true;

  nativeBuildInputs = [
    cmake
    cmake.configurePhaseHook
  ];

  buildInputs = [ gtest ];

  meta = {
    description = "Open-source collection of C++ code designed to augment the C++ standard library";
    homepage = "https://abseil.io/";
    changelog = "https://github.com/abseil/abseil-cpp/releases/tag/${finalAttrs.version}";
    license = lib.licenses.asl20;
    platforms = lib.platforms.all;

  };
})
