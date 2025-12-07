{
  version,
  src-urls,
  src-hash,
  configureFlags ? [ ],
  patches ? [ ],
  packageAtLeast,
  packageOlder,
  mkVariantPassthru,
  ...
}@variantArgs:

{
  lib,
  stdenv,
  fetchurl,
  gmp,
  autoreconfHook,
  buildPackages,
  updateAutotoolsGnuConfigScriptsHook,
}@args:

stdenv.mkDerivation {
  pname = "isl";
  inherit version;

  src = fetchurl {
    urls = src-urls;
    hash = src-hash;
  };

  inherit patches;

  strictDeps = true;
  depsBuildBuild = lib.optionals (packageAtLeast "0.23") [ buildPackages.stdenv.cc ];
  nativeBuildInputs =
    lib.optionals (stdenv.hostPlatform.isRiscV && packageOlder "0.23") [
      autoreconfHook
    ]
    ++ [
      # needed until config scripts are updated to not use /usr/bin/uname on FreeBSD native
      updateAutotoolsGnuConfigScriptsHook
    ];
  buildInputs = [ gmp ];

  inherit configureFlags;

  enableParallelBuilding = true;
  passthru = mkVariantPassthru variantArgs args;

  meta = {
    homepage = "https://libisl.sourceforge.io/";
    license = lib.licenses.lgpl21;
    description = "Library for manipulating sets and relations of integer points bounded by linear constraints";
    platforms = lib.platforms.all;
  };
}
