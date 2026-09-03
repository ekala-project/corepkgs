# qbe — Small compiler backend written in C
{
  lib,
  stdenv,
  fetchzip,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "qbe";
  version = "1.2";

  src = fetchzip {
    url = "https://c9x.me/compile/release/qbe-${finalAttrs.version}.tar.xz";
    hash = "sha256-UgtJnZF/YtD54OBy9HzGRAEHx5tC9Wo2YcUidGwrv+s=";
  };

  patches = [
    ./001-dont-hardcode-tmp.patch
  ];

  makeFlags = [
    "PREFIX=$(out)"
    "CC=${stdenv.cc.targetPrefix}cc"
  ];

  enableParallelBuilding = true;

  meta = {
    description = "Small compiler backend written in C";
    homepage = "https://c9x.me/compile/";
    license = lib.licenses.mit;
    mainProgram = "qbe";
    platforms = lib.platforms.all;
  };
})
