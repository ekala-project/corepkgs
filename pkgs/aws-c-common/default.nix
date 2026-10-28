{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
  nix,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "aws-c-common";
  # nixpkgs-update: no auto update
  version = "1.0.3";

  outputs = [
    "out"
    "include"
  ];

  src = fetchFromGitHub {
    owner = "awslabs";
    repo = "aws-c-common";
    tag = "v${finalAttrs.version}";
    hash = "sha256-1FJyf1ADDezaUCpM1TQESC1k8Yn3/EOKZvlZe5wpBMg=";
  };

  nativeBuildInputs = [
    cmake
    cmake.configurePhaseHook
  ];

  cmakeEntries = {
    BUILD_SHARED_LIBS = true;
    ${if stdenv.hostPlatform.isRiscV then "CMAKE_C_FLAGS" else null} = "-fasynchronous-unwind-tables";
  };

  # aws-c-common misuses cmake modules, so we need
  # to manually add a MODULE_PATH to its consumers
  setupHook = ./setup-hook.sh;

  # Prevent the execution of tests known to be flaky.
  preCheck =
    let
      ignoreTests = [
        "promise_test_multiple_waiters"
        # Flaky test https://github.com/NixOS/nixpkgs/issues/443233
        "test_memory_usage_maxrss"
      ];
    in
    ''
      cat <<EOW >CTestCustom.cmake
      SET(CTEST_CUSTOM_TESTS_IGNORE ${toString ignoreTests})
      EOW
    '';

  passthru.tests = {
    inherit nix;
  };

  meta = {
    description = "AWS SDK for C common core";
    homepage = "https://github.com/awslabs/aws-c-common";
    license = lib.licenses.asl20;
    platforms = lib.platforms.unix;
    # https://github.com/awslabs/aws-c-common/issues/1175
    badPlatforms = lib.platforms.bigEndian;
    identifiers.cpeParts = lib.meta.cpeFullVersionWithVendor "amazon" finalAttrs.version;
  };
})
