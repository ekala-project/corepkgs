{
  lib,
  stdenvNoCC,
  rustPlatform,
  fetchFromGitHub,
  fetchElmDeps,
  elm,
  nodejs,
  uglify-js,
  pkg-config,
  perl,
  makeWrapper,
  openssl,
  sqlite,
  nix,
  nix-eval-jobs,
  git,
  gh,
  gnutar,
  xz,
  coreutils,
}:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "ekapkgs-update";
  version = "0.1.0-unstable-2026-11-15";

  src = fetchFromGitHub {
    owner = "ekala-project";
    repo = "ekapkgs-update";
    rev = "5946e907cbee7735965c7c4203bd62a3cf88004f";
    hash = "sha256-G7uxNCvi8XCNCvulJDPhf6hth85giJF4TEMAh7EbiZA=";
  };

  cargoHash = "sha256-XGIQljMlYDA1rtAdMs9ne2vTmoaOz3T+Pzz1LHYSMUo=";

  # The updater and its web monitoring portal.
  cargoBuildFlags = [
    "-p"
    "ekapkgs-update"
    "-p"
    "ekapkgs-update-web"
  ];
  cargoTestFlags = finalAttrs.cargoBuildFlags;

  nativeBuildInputs = [
    perl
    pkg-config
    makeWrapper
  ];

  buildInputs = [
    openssl
    sqlite
  ];

  env = {
    OPENSSL_NO_VENDOR = "1";
    LIBSQLITE3_SYS_USE_PKG_CONFIG = "1";
    # build.rs embeds this pre-compiled Elm bundle instead of running `elm`
    # (which would need network access for its packages).
    EKAPKGS_WEB_ELM_JS = "${finalAttrs.passthru.frontend}/elm.js";
  };

  # The daemon is usually launched from a service manager, so make sure the
  # tools it shells out to are on PATH.
  postFixup = ''
    wrapProgram $out/bin/ekapkgs-update \
      --prefix PATH : ${
        lib.makeBinPath [
          # TODO(corepkgs): Port cachix for pushing build results
          nix
          git
          gh
          nix-eval-jobs
          gnutar
          xz
          coreutils
        ]
      }
  '';

  passthru.frontend = stdenvNoCC.mkDerivation {
    pname = "ekapkgs-update-web-frontend";
    inherit (finalAttrs) version src;
    sourceRoot = "${finalAttrs.src.name}/ekapkgs-update-web/frontend";

    nativeBuildInputs = [
      elm
      nodejs
    ];

    # Copied from upstream's nix/web-frontend/; regenerate them with its
    # update.sh when elm.json changes.
    configurePhase = ''
      runHook preConfigure
      ${fetchElmDeps {
        elmPackages = import ./elm-srcs.nix;
        registryDat = ./registry.dat;
        elmVersion = elm.version;
      }}
      runHook postConfigure
    '';

    # Minified following Elm's "Minification" guide: one compress pass that
    # may drop calls to Elm's pure currying helpers, then a mangle pass.
    buildPhase =
      let
        uglifyjs = "node ${uglify-js}/lib/node_modules/uglify-js/bin/uglifyjs";
      in
      ''
        runHook preBuild
        elm make src/Main.elm --optimize --output=elm.unminified.js
        ${uglifyjs} elm.unminified.js \
          --compress 'pure_funcs=[F2,F3,F4,F5,F6,F7,F8,F9,A2,A3,A4,A5,A6,A7,A8,A9],pure_getters,keep_fargs=false,unsafe_comps,unsafe' \
          | ${uglifyjs} --mangle --output elm.js
        runHook postBuild
      '';

    installPhase = ''
      runHook preInstall
      install -Dm644 elm.js "$out/elm.js"
      runHook postInstall
    '';

    meta = {
      description = "Elm frontend of the ekapkgs-update web dashboard";
      inherit (elm.meta) platforms;
    };
  };

  meta = {
    description = "Automated package update tool for ekapkgs (and similar Nix package sets)";
    homepage = "https://github.com/ekala-project/ekapkgs-update";
    license = lib.licenses.bsd3;
    inherit (elm.meta) platforms;
    mainProgram = "ekapkgs-update";
  };
})
