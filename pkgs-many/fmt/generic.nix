{
  version,
  src-hash,
  patches ? [ ],
  mkVariantPassthru,
  ...
}@variantArgs:

{
  lib,
  stdenv,
  fetchFromGitHub,
  fetchpatch,
  cmake,
  enableShared ? !stdenv.hostPlatform.isStatic,

  # tests
  mpd,
  openimageio,
  fcitx5,
  spdlog,
}:

stdenv.mkDerivation {
  pname = "fmt";
  inherit version;

  outputs = [
    "out"
    "dev"
  ];

  src = fetchFromGitHub {
    owner = "fmtlib";
    repo = "fmt";
    rev = version;
    hash = src-hash;
  };

  patches = map (p: fetchpatch p) patches;

  nativeBuildInputs = [
    cmake
    cmake.configurePhaseHook
  ];

  cmakeFlags = [ (lib.cmakeBool "BUILD_SHARED_LIBS" enableShared) ];

  doCheck = true;

  passthru = mkVariantPassthru variantArgs // {
    tests = {
      inherit
        mpd
        openimageio
        fcitx5
        spdlog
        ;
    };
  };

  meta = with lib; {
    description = "Small, safe and fast formatting library";
    longDescription = ''
      fmt (formerly cppformat) is an open-source formatting library. It can be
      used as a fast and safe alternative to printf and IOStreams.
    '';
    homepage = "https://fmt.dev/";
    changelog = "https://github.com/fmtlib/fmt/blob/${version}/ChangeLog.rst";
    downloadPage = "https://github.com/fmtlib/fmt/";
    maintainers = [ ];
    license = licenses.mit;
    platforms = platforms.all;
  };
}
