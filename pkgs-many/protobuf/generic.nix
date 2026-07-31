# The cmake version of this build is meant to enable both cmake and .pc being exported
# this is important because grpc exports a .cmake file which also expects for protobuf
# to have been exported through cmake as well.
{
  version,
  hash,
  packageAtLeast,
  packageOlder,
  ...
}@variantArgs:

{
  lib,
  stdenv,
  abseil-cpp,
  buildPackages,
  cmake,
  fetchFromGitHub,
  fetchpatch,
  gtest,
  zlib,
  replaceVars,
  versionCheckHook,

  # downstream dependencies
  python3,
  grpc,
  enableShared ? !stdenv.hostPlatform.isStatic,

  testers,
  protobuf,
  ...
}@args:

stdenv.mkDerivation (finalAttrs: {
  pname = "protobuf";
  inherit version;

  src = fetchFromGitHub {
    owner = "protocolbuffers";
    repo = "protobuf";
    tag = "v${version}";
    inherit hash;
  };

  postPatch =
    lib.optionalString (stdenv.hostPlatform.isDarwin && packageOlder "29") ''
      substituteInPlace src/google/protobuf/testing/googletest.cc \
        --replace-fail 'tmpnam(b)' '"'$TMPDIR'/foo"'
    ''
    + lib.optionalString (packageAtLeast "25" && packageOlder "27") ''
      # Fix missing #include <cstring> in utf8_validity.cc (needed with newer compilers)
      sed -i '1i #include <cstring>' third_party/utf8_range/utf8_validity.cc
    ''
    + lib.optionalString (packageAtLeast "27" && packageOlder "30") ''
      # Remove absl::if_constexpr CMake target reference, removed in newer abseil-cpp
      sed -i '/absl::if_constexpr/d' cmake/abseil-cpp.cmake

      # Provide compatibility shim for absl/utility/internal/if_constexpr.h,
      # which was removed in abseil-cpp 20260526
      mkdir -p absl_shim/absl/utility/internal
      cat > absl_shim/absl/utility/internal/if_constexpr.h << 'SHIMEOF'
      #ifndef ABSL_UTILITY_INTERNAL_IF_CONSTEXPR_H_
      #define ABSL_UTILITY_INTERNAL_IF_CONSTEXPR_H_
      #include <type_traits>
      #include <utility>
      namespace absl {
      namespace utility_internal {

      template <bool condition>
      struct IfConstexprElseImpl;

      template <>
      struct IfConstexprElseImpl<true> {
        template <typename TrueFunc, typename FalseFunc, typename... Args>
        static auto Run(TrueFunc&& true_func, FalseFunc&&, Args&&... args)
            -> decltype(std::forward<TrueFunc>(true_func)(std::forward<Args>(args)...)) {
          return std::forward<TrueFunc>(true_func)(std::forward<Args>(args)...);
        }
      };

      template <>
      struct IfConstexprElseImpl<false> {
        template <typename TrueFunc, typename FalseFunc, typename... Args>
        static auto Run(TrueFunc&&, FalseFunc&& false_func, Args&&... args)
            -> decltype(std::forward<FalseFunc>(false_func)(std::forward<Args>(args)...)) {
          return std::forward<FalseFunc>(false_func)(std::forward<Args>(args)...);
        }
      };

      template <bool condition, typename TrueFunc, typename FalseFunc, typename... Args>
      auto IfConstexprElse(TrueFunc&& true_func, FalseFunc&& false_func, Args&&... args)
          -> decltype(IfConstexprElseImpl<condition>::Run(
              std::forward<TrueFunc>(true_func),
              std::forward<FalseFunc>(false_func),
              std::forward<Args>(args)...)) {
        return IfConstexprElseImpl<condition>::Run(
            std::forward<TrueFunc>(true_func),
            std::forward<FalseFunc>(false_func),
            std::forward<Args>(args)...);
      }

      }  // namespace utility_internal
      }  // namespace absl
      #endif  // ABSL_UTILITY_INTERNAL_IF_CONSTEXPR_H_
      SHIMEOF
      export NIX_CFLAGS_COMPILE="''${NIX_CFLAGS_COMPILE:-} -isystem $(pwd)/absl_shim"
    '';

  patches =
    lib.optionals (packageOlder "22") [
      # fix protobuf-targets.cmake installation paths, and allow for CMAKE_INSTALL_LIBDIR to be absolute
      # https://github.com/protocolbuffers/protobuf/pull/10090
      (fetchpatch {
        url = "https://github.com/protocolbuffers/protobuf/commit/a7324f88e92bc16b57f3683403b6c993bf68070b.patch";
        hash = "sha256-SmwaUjOjjZulg/wgNmR/F5b8rhYA2wkKAjHIOxjcQdQ=";
      })
    ]
    ++ lib.optionals (packageAtLeast "29" && packageOlder "30") [
      # fix temporary directory handling to avoid test failures on darwin
      # https://github.com/NixOS/nixpkgs/issues/464439
      (fetchpatch {
        url = "https://github.com/protocolbuffers/protobuf/commit/0e9d0f6e77280b7a597ebe8361156d6bb1971dca.patch";
        hash = "sha256-rIP+Ft/SWVwh9Oy8y8GSUBgP6CtLCLvGmr6nOqmyHhY=";
      })
    ];

  # hook to provide the path to protoc executable, used at build time
  build_protobuf =
    if (!stdenv.buildPlatform.canExecute stdenv.hostPlatform) then
      buildPackages."protobuf_${builtins.substring 0 2 version}"
    else
      (placeholder "out");
  setupHook = ./setup-hook.sh;

  nativeBuildInputs = [
    cmake
    cmake.configurePhaseHook
  ];

  buildInputs = [
    gtest
    zlib
  ];

  propagatedBuildInputs = [
    abseil-cpp
  ];

  strictDeps = true;

  cmakeDir = if packageOlder "22" then "../cmake" else null;
  cmakeFlags = [
    "-Dprotobuf_USE_EXTERNAL_GTEST=ON"
    "-Dprotobuf_ABSL_PROVIDER=package"
  ]
  ++ lib.optionals enableShared [
    "-Dprotobuf_BUILD_SHARED_LIBS=ON"
  ]
  ++ lib.optionals (!finalAttrs.finalPackage.doCheck) [
    "-Dprotobuf_BUILD_TESTS=OFF"
  ];

  doCheck =
    # Tests fail to build on 32-bit platforms; fixed in 22.x
    # https://github.com/protocolbuffers/protobuf/issues/10418
    # Also AnyTest.TestPackFromSerializationExceedsSizeLimit fails on 32-bit platforms
    # https://github.com/protocolbuffers/protobuf/issues/8460
    !stdenv.hostPlatform.is32bit
    # Older protobuf versions (< 30) reference absl::if_constexpr in their test
    # CMake config, which was removed in newer abseil-cpp releases
    && packageAtLeast "30";

  nativeInstallCheckInputs = [
    versionCheckHook
  ];
  versionCheckProgram = [ "${placeholder "out"}/bin/protoc" ];
  doInstallCheck = true;

  env = lib.optionalAttrs (packageAtLeast "29" && packageOlder "30") {
    GTEST_DEATH_TEST_STYLE = "threadsafe";
  };

  passthru = {
    tests = {
      pythonProtobuf = python3.pkgs.protobuf;
      inherit grpc;
      version = testers.testVersion { package = protobuf; };
    };

    inherit abseil-cpp;
  };

  meta = {
    description = "Google's data interchange format";
    longDescription = ''
      Protocol Buffers are a way of encoding structured data in an efficient
      yet extensible format. Google uses Protocol Buffers for almost all of
      its internal RPC protocols and file formats.
    '';
    license = lib.licenses.bsd3;
    platforms = lib.platforms.all;
    homepage = "https://protobuf.dev/";

    mainProgram = "protoc";
  };
})
