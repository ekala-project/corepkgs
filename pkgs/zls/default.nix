# zls — Zig Language Server
{
  lib,
  stdenv,
  fetchFromGitHub,
  zig,
  callPackage,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "zls";
  version = "0.16.0";

  src = fetchFromGitHub {
    owner = "zigtools";
    repo = "zls";
    tag = finalAttrs.version;
    fetchSubmodules = true;
    hash = "sha256-k0xWObsw9K12BKfK+UB5TieWDFEFfBQhN1X1NO35fWk=";
  };

  nativeBuildInputs = [ zig ];

  strictDeps = true;
  __structuredAttrs = true;

  dontConfigure = true;

  zigBuildFlags = [
    "--system"
    "${callPackage ./deps.nix { }}"
  ];

  buildPhase = ''
    runHook preBuild

    export ZIG_GLOBAL_CACHE_DIR="$TMPDIR/zig-cache"
    export ZIG_LOCAL_CACHE_DIR="$TMPDIR/zig-local-cache"

    zig build ''${zigBuildFlags[@]} -Doptimize=ReleaseSafe

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    install -Dm755 zig-out/bin/zls $out/bin/zls
    runHook postInstall
  '';

  meta = {
    description = "Zig LSP implementation + Zig Language Server";
    homepage = "https://github.com/zigtools/zls";
    license = lib.licenses.mit;
    mainProgram = "zls";
    platforms = lib.platforms.unix;
  };
})
