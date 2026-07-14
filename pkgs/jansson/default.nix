{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
  jshon,
  nghttp2,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "jansson";
  version = "2.15.1";

  outputs = [
    "dev"
    "out"
  ];

  src = fetchFromGitHub {
    owner = "akheron";
    repo = "jansson";
    tag = "v${finalAttrs.version}";
    hash = "sha256-iOOZyrNlCbibT7qozH7B2RjAgG9yv+B2ldAaz8U6IhQ=";
  };

  nativeBuildInputs = [
    cmake
    cmake.configurePhaseHook
  ];

  cmakeFlags = [
    # networkmanager relies on libjansson.so:
    #   https://github.com/NixOS/nixpkgs/pull/176302#issuecomment-1150239453
    "-DJANSSON_BUILD_SHARED_LIBS=${if stdenv.hostPlatform.isStatic then "OFF" else "ON"}"

    # Fix the build with CMake 4.
    #
    # Remove on next release; upstream fix is coupled with additional
    # changes in <https://github.com/akheron/jansson/pull/692>.
    "-DCMAKE_POLICY_VERSION_MINIMUM=3.10"
  ];

  postFixup = ''
    # Incorrectly references the dev output, libjansson.so is in out
    substituteInPlace $dev/lib/cmake/jansson/janssonTargets-release.cmake \
      --replace-fail "''${_IMPORT_PREFIX}/lib" "$out/lib"
  '';

  passthru.tests = {
    inherit jshon nghttp2;
  };

  meta = {
    description = "C library for encoding, decoding and manipulating JSON data";
    homepage = "https://github.com/akheron/jansson";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
    maintainers = [ ];
  };
})
