{
  lib,
  stdenv,
  fetchFromGitHub,
  atf,
  autoreconfHook,
  kyua,
  lua,
  pkg-config,

}:

lib.fix (
  drv:
  let
    # Avoid infinite recursions:
    # - Lutok depends on ATF and Kyua for testing; but
    # - ATF depends on Kyua for testing, and Kyua depends on Lutok as a build input.
    # To break the cycle (ATF -> Kyua -> Lutok -> ATF and Kyua):
    # - Build ATF without testing (avoiding the Kyua dependency); and
    # - Build Kyua against a version of Lutok without testing (also avoiding the ATF and Kyua dependencies).
    atf' = atf.overrideAttrs (_: {
      doInstallCheck = false;
    });
    kyua' =
      (kyua.override {
        lutok = drv.overrideAttrs (_: {
          doCheck = false;
        });
      }).overrideAttrs
        (_: {
          # Assume Kyua's install check phase will run when Kyua is built. Don't run it again
          # while building Lutok because it can take four to five minutes to run.
          doInstallCheck = false;
        });
  in
  stdenv.mkDerivation (finalAttrs: {
    pname = "lutok";
    version = "0.6.3";

    outputs = [
      "out"
      "dev"
    ];

    src = fetchFromGitHub {
      owner = "freebsd";
      repo = "lutok";
      tag = "lutok-${finalAttrs.version}";
      hash = "sha256-HpTs/BF0F3jFZrh6K5X6z6T9ySK/EsR/KZw1462RDTY=";
    };

    strictDeps = true;

    propagatedBuildInputs = [ lua ];

    nativeBuildInputs = [
      atf'
      autoreconfHook
      pkg-config
    ];

    enableParallelBuilding = true;

    makeFlags = [
      # Lutok isn't compatible with C++17, which is the default on current clang and GCC.
      "CXXFLAGS=-std=c++11"
    ];

    doCheck = true;

    checkInputs = [ atf' ];
    nativeCheckInputs = [ kyua' ];

    # Test programs are built by "make check", not the default target.
    # Override checkPhase to build and run tests together via make.
    checkPhase = ''
      runHook preCheck
      make -j''${NIX_BUILD_CORES:-1} check
      runHook postCheck
    '';

    meta = {
      description = "Lightweight C++ API for Lua";
      homepage = "https://github.com/freebsd/lutok/";
      license = lib.licenses.bsd3;

      platforms = lib.platforms.unix;
    };
  })
)
