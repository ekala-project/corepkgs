{
  lib,
  stdenv,
  stdenvNoCC,
  rustPlatform,
  fetchFromGitHub,
  fetchElmDeps,
  elm,
  makeWrapper,
  pkg-config,
  protobuf,
  openssl,
  nix,
  iets,
  git,
  bubblewrap,
  passt,
}:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "eka-ci";
  version = "0.1.0-unstable-2026-11-08";

  src = fetchFromGitHub {
    owner = "ekala-project";
    repo = "eka-ci";
    rev = "484f76ed27a612db766cfc881a0a8191914c788d";
    # These test fixtures (only compiled under cfg(test)) contain real store
    # paths, which a fixed-output derivation may not reference.
    postFetch = ''
      rm $out/backend/server/src/tests/*.json
    '';
    hash = "sha256-czLtO9stFcrEfJj85uchlWhxjYuhTWSXqxQqPnnubsU=";
  };

  sourceRoot = "${finalAttrs.src.name}/backend";

  cargoHash = "sha256-oV/ooeCH+rQiQnOmE3w1KYbXKUDvsGzMCtVXsm0ZrC4=";

  nativeBuildInputs = [
    pkg-config
    protobuf
    makeWrapper
  ];

  buildInputs = [ openssl ];

  env = {
    OPENSSL_NO_VENDOR = "1";
  }
  // lib.optionalAttrs (stdenv.hostPlatform.isLinux && stdenv.hostPlatform.isx86_64) {
    RUSTFLAGS = "-C linker-features=-lld";
  };

  postInstall = ''
    mkdir -p $out/share/eka-ci
    ln -s ${finalAttrs.passthru.frontend} $out/share/eka-ci/static

    for bin in $out/bin/*; do
      wrapProgram "$bin" \
        --prefix PATH : ${
          lib.makeBinPath [
            nix
            iets
            git
            bubblewrap
            passt
          ]
        }
    done
  '';

  passthru.frontend = stdenvNoCC.mkDerivation {
    pname = "eka-ci-frontend";
    inherit (finalAttrs) version src;
    sourceRoot = "${finalAttrs.src.name}/frontend";

    nativeBuildInputs = [ elm ];

    # Package pins from upstream's frontend/elm-srcs.nix, rehashed as
    # unpacked tarballs for fetchElmDeps; update them when elm.json changes.
    configurePhase = ''
      runHook preConfigure
      ${fetchElmDeps {
        elmPackages = import ./elm-srcs.nix;
        registryDat = ./registry.dat;
        elmVersion = elm.version;
      }}
      runHook postConfigure
    '';

    buildPhase = ''
      runHook preBuild
      elm make src/Main.elm --optimize --output=static/main.js
      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall
      cp -r static $out
      runHook postInstall
    '';

    meta = {
      description = "Elm frontend of the eka-ci web interface";
      inherit (elm.meta) platforms;
    };
  };

  meta = {
    description = "Continuous integration server for Nix";
    homepage = "https://github.com/ekala-project/eka-ci";
    license = lib.licenses.agpl3Only;
    platforms = lib.platforms.linux;
    mainProgram = "eka_ci_server";
  };
})
