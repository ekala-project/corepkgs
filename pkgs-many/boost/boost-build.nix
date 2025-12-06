{ lib
, stdenv
, fetchFromGitHub
, bison
, src
, version
, boostBuildPatches ? []
, packageAtLeast
, packageOlder
}:

stdenv.mkDerivation {
  pname = "boost-build";
  inherit src version;

  # b2 is in a subdirectory of boost source tarballs
  prePatch = ''
    cd tools/build
  '';

  patches = boostBuildPatches;

  # Upstream defaults to gcc on darwin, but we use clang.
  postPatch = ''
    substituteInPlace src/build-system.jam \
    --replace "default-toolset = darwin" "default-toolset = clang-darwin"
  '' + lib.optionalString (packageAtLeast "1.82") ''
    patchShebangs --build src/engine/build.sh
  '';

  nativeBuildInputs = [
    bison
  ];

  buildPhase = ''
    runHook preBuild
    ./bootstrap.sh
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    ./b2 ${lib.optionalString (stdenv.cc.isClang) "toolset=clang "}install --prefix="$out"

    # older versions of b2 created this symlink,
    # which we want to support building via useBoost.
    test -e "$out/bin/bjam" || ln -s b2 "$out/bin/bjam"

    runHook postInstall
  '';

  meta = with lib; {
    homepage = "https://www.boost.org/build/";
    license = lib.licenses.boost;
    platforms = platforms.unix;
    maintainers = [ ];
  };
}

