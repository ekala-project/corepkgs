{
  stdenv,
  lib,
  fetchurl,
  autoPatchelfHook,
  gmp,
  ncurses,
  zlib,
}:

let
  # Upstream release binaries; both are built from the same 0.19.2 sources.
  sources = {
    x86_64-linux = {
      name = "linux-x64";
      hash = "sha256-ZjINJ3AWVPoRvQ6NhL35gpaU1XcMjc7i3t5hYPrVhzc=";
    };
    aarch64-linux = {
      name = "linux-arm";
      hash = "sha256-orsj6K+MmHTtH3AP26TSVjZpkxPf8EaVWYxBBVAoyPU=";
    };
  };
  source =
    sources.${stdenv.hostPlatform.system}
      or (throw "elm: unsupported platform ${stdenv.hostPlatform.system}");
in
stdenv.mkDerivation (finalAttrs: {
  pname = "elm";
  version = "0.19.2";

  src = fetchurl {
    url = "https://github.com/elm/compiler/releases/download/${finalAttrs.version}/elm-${finalAttrs.version}-${source.name}.gz";
    inherit (source) hash;
  };

  nativeBuildInputs = [ autoPatchelfHook ];

  buildInputs = [
    (lib.getLib stdenv.cc.cc)
    gmp
    ncurses
    zlib
  ];

  dontUnpack = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin
    zcat $src > $out/bin/elm
    chmod +x $out/bin/elm
    runHook postInstall
  '';

  passthru.ekapkgs-update.github-repo = "elm/compiler";

  meta = {
    description = "Compiler for Elm, a functional language for reliable web apps";
    homepage = "https://elm-lang.org/";
    license = lib.licenses.bsd3;
    platforms = builtins.attrNames sources;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    mainProgram = "elm";
  };
})
