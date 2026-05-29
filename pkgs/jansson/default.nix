{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "jansson";
  version = "2.15.0";

  outputs = [
    "dev"
    "out"
  ];

  src = fetchFromGitHub {
    owner = "akheron";
    repo = "jansson";
    tag = "v${finalAttrs.version}";
    hash = "sha256-s7g1QvJjl9LsWw+VZsTQHCoEgw2Ad9+8V0b2NFml5rw=";
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

  meta = {
    description = "C library for encoding, decoding and manipulating JSON data";
    homepage = "https://github.com/akheron/jansson";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
    maintainers = [ ];
  };
})
