# odin — Programming language for high-performance systems
{
  lib,
  fetchFromGitHub,
  makeBinaryWrapper,
  which,
  llvmPackages,
}:

let
  inherit (llvmPackages) stdenv;
in
stdenv.mkDerivation (finalAttrs: {
  pname = "odin";
  version = "dev-2026-07a";

  src = fetchFromGitHub {
    owner = "odin-lang";
    repo = "Odin";
    tag = finalAttrs.version;
    hash = "sha256-sjL6mj2zfUVpiwkooTTBCVkPRoPWR7ci/hb9TYF+J/I=";
  };

  patches = [
    ./darwin-remove-impure-links.patch
    ./system-raylib.patch
  ];

  postPatch = ''
    substituteInPlace src/build_settings.cpp \
      --replace-fail "arm64-apple-macosx" "arm64-apple-darwin"

    rm -r vendor/raylib/{linux,macos,wasm,windows}

    patchShebangs --build build_odin.sh
  '';

  env.LLVM_CONFIG = lib.getExe' llvmPackages.llvm.dev "llvm-config";

  dontConfigure = true;

  buildFlags = [ "release" ];

  nativeBuildInputs = [
    makeBinaryWrapper
    which
  ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin
    cp odin $out/bin/odin

    mkdir -p $out/share
    cp -r {base,core,vendor,shared} $out/share

    wrapProgram $out/bin/odin \
      --prefix PATH : ${
        lib.makeBinPath (
          with llvmPackages;
          [
            bintools
            llvm
            clang
            lld
          ]
        )
      } \
      --set-default ODIN_ROOT $out/share

    make -C "$out/share/vendor/cgltf/src/"
    make -C "$out/share/vendor/stb/src/"
    make -C "$out/share/vendor/miniaudio/src/"

    runHook postInstall
  '';

  meta = {
    description = "Fast, concise, readable programming language";
    homepage = "https://odin-lang.org/";
    license = lib.licenses.bsd3;
    mainProgram = "odin";
    platforms = lib.platforms.unix;
  };
})
