{
  lib,
  stdenv,
  cmake,
  fetchFromGitHub,
  git,
  gmp,
  cadical,
  leangz,
  makeWrapper,
  pkg-config,
  libuv,
  enableMimalloc ? true,
  perl,
}:

let
  cadical' = cadical.override { version = "2.1.3"; };
in

stdenv.mkDerivation (finalAttrs: {
  pname = "lean4";
  version = "4.30.0";

  mimalloc-src = fetchFromGitHub {
    owner = "microsoft";
    repo = "mimalloc";
    tag = "v2.2.3";
    hash = "sha256-B0gngv16WFLBtrtG5NqA2m5e95bYVcQraeITcOX9A74=";
  };

  src = fetchFromGitHub {
    owner = "leanprover";
    repo = "lean4";
    tag = "v${finalAttrs.version}";
    hash = "sha256-YTsfIppd6km7wOjAxRH5KMPsW++ztFDCJT2up72J86Q=";
  };

  postPatch =
    let
      pattern = "\${LEAN_BINARY_DIR}/../mimalloc/src/mimalloc";
    in
    ''
      substituteInPlace src/CMakeLists.txt \
        --replace-fail 'set(GIT_SHA1 "")' 'set(GIT_SHA1 "${finalAttrs.src.tag}")'

      # Remove tests that fails in sandbox.
      # It expects `sourceRoot` to be a git repository.
      rm -rf src/lake/examples/git/
    ''
    + (lib.optionalString enableMimalloc ''
      substituteInPlace CMakeLists.txt \
        --replace-fail 'MIMALLOC-SRC' '${finalAttrs.mimalloc-src}'
      for file in stage0/src/CMakeLists.txt stage0/src/runtime/CMakeLists.txt src/CMakeLists.txt src/runtime/CMakeLists.txt; do
        substituteInPlace "$file" \
          --replace-fail '${pattern}' '${finalAttrs.mimalloc-src}'
      done
    '');

  preConfigure = ''
    patchShebangs stage0/src/bin/ src/bin/
  '';

  nativeBuildInputs = [
    cmake
    cmake.configurePhaseHook
    pkg-config
    makeWrapper
    leangz
  ];

  buildInputs = [
    gmp
    libuv
    cadical'
  ];

  postInstall = ''
    wrapProgram $out/bin/lean \
      --prefix PATH : ${cadical'}/bin
  '';

  patches = [ ./mimalloc.patch ];

  cmakeFlags = [
    "-DUSE_GITHASH=OFF"
    "-DINSTALL_LICENSE=OFF"
    "-DINSTALL_CADICAL=OFF"
    "-DUSE_MIMALLOC=${if enableMimalloc then "ON" else "OFF"}"
  ];

  meta = {
    description = "Automatic and interactive theorem prover";
    homepage = "https://leanprover.github.io/";
    license = lib.licenses.asl20;
    platforms = lib.platforms.all;
    mainProgram = "lean";
  };
})
