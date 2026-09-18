{
  lib,
  stdenv,
  fetchFromGitHub,
  gfortran,
  cmake,
  shared ? true,
  # Compile with ILP64 interface
  blas64 ? false,
  testers,
  runUnitTests,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "liblapack";
  version = "3.12.1";

  src = fetchFromGitHub {
    owner = "Reference-LAPACK";
    repo = "lapack";
    rev = "v${finalAttrs.version}";
    sha256 = "sha256-SfKsvZ07v87tFFd9bnkIEdervyX/ucLfs/TOsl08aKQ=";
  };

  nativeBuildInputs = [
    gfortran
    cmake
    cmake.configurePhaseHook
  ];

  # Configure stage fails on aarch64-darwin otherwise, due to either clang 11 or gfortran 10.
  hardeningDisable = lib.optionals (stdenv.hostPlatform.isDarwin && stdenv.hostPlatform.isAarch64) [
    "stackprotector"
  ];

  cmakeEntries = {
    CMAKE_Fortran_FLAGS = "-fPIC";
    LAPACKE = "ON";
    CBLAS = "ON";
    BUILD_TESTING = "ON";
    ${if shared then "BUILD_SHARED_LIBS" else null} = "ON";
    ${if blas64 then "BUILD_INDEX64" else null} = "ON";
    # Tries to run host platform binaries during the build
    # Will likely be disabled by default in 3.12, see:
    # https://github.com/Reference-LAPACK/lapack/issues/757
    ${if !stdenv.buildPlatform.canExecute stdenv.hostPlatform then "TEST_FORTRAN_COMPILER" else null} =
      "OFF";
  };

  passthru = { inherit blas64; };

  postInstall =
    let
      canonicalExtension =
        if stdenv.hostPlatform.isLinux then
          "${stdenv.hostPlatform.extensions.sharedLibrary}.${lib.versions.major finalAttrs.version}"
        else
          stdenv.hostPlatform.extensions.sharedLibrary;
    in
    lib.optionalString blas64 ''
      ln -s $out/lib/liblapack64${canonicalExtension} $out/lib/liblapack${canonicalExtension}
      ln -s $out/lib/liblapacke64${canonicalExtension} $out/lib/liblapacke${canonicalExtension}
    '';

  # Some CBLAS related tests fail on Darwin:
  #  14 - CBLAS-xscblat2 (Failed)
  #  15 - CBLAS-xscblat3 (Failed)
  #  17 - CBLAS-xdcblat2 (Failed)
  #  18 - CBLAS-xdcblat3 (Failed)
  #  20 - CBLAS-xccblat2 (Failed)
  #  21 - CBLAS-xccblat3 (Failed)
  #  23 - CBLAS-xzcblat2 (Failed)
  #  24 - CBLAS-xzcblat3 (Failed)
  #
  # Upstream issue to track:
  # * https://github.com/Reference-LAPACK/lapack/issues/440
  ctestArgs = lib.optionalString stdenv.hostPlatform.isDarwin "-E '^(CBLAS-(x[sdcz]cblat[23]))$'";

  checkPhase = ''
    runHook preCheck
    ctest ${finalAttrs.ctestArgs}
    runHook postCheck
  '';

  passthru.tests = {
    pkg-config = testers.testMetaPkgConfig finalAttrs.finalPackage;
    unittests = runUnitTests finalAttrs.finalPackage;
  };

  meta = {
    description = "Linear Algebra PACKage";
    homepage = "http://www.netlib.org/lapack/";
    license = lib.licenses.bsd3;
    pkgConfigModules = [ "lapack" ];
    platforms = lib.platforms.all;
  };
})
