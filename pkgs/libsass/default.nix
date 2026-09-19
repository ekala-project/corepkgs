{
  lib,
  stdenv,
  fetchFromGitHub,
  autoreconfHook,
  testers,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "libsass";
  version = "3.6.6";

  src = fetchFromGitHub {
    owner = "sass";
    repo = "libsass";
    rev = finalAttrs.version;
    hash = "sha256-FkLL3OAJXDptRQY6ZkYbss2pcc40f/wasIvEIyHRQFo=";
    postFetch = ''
      rm -r $out/test/e2e/unicode-pwd
    '';
  };

  preConfigure = ''
    export LIBSASS_VERSION=${finalAttrs.version}
  '';

  nativeBuildInputs = [ autoreconfHook ];

  passthru.tests = {
    pkg-config = testers.testMetaPkgConfig finalAttrs.finalPackage;
  };

  meta = {
    description = "C/C++ implementation of a Sass compiler";
    homepage = "https://github.com/sass/libsass";
    license = lib.licenses.mit;
    pkgConfigModules = [ "libsass" ];
    platforms = lib.platforms.unix;
  };
})
