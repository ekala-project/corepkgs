# Pkl — Apple's configuration language (prebuilt binary)
{
  lib,
  stdenv,
  fetchurl,
  makeWrapper,
  zlib,
}:

let
  version = "0.32.1";

  srcs = {
    x86_64-linux = fetchurl {
      url = "https://github.com/apple/pkl/releases/download/${version}/pkl-linux-amd64";
      hash = "sha256-MYC2LalcDK0dkE6btsX0qPkDJBPCHlMZS7kf8e5fMhE=";
    };
    aarch64-linux = fetchurl {
      url = "https://github.com/apple/pkl/releases/download/${version}/pkl-linux-aarch64";
      hash = "sha256-p20t1H2kNaj5EbA0c3P0fH5Z6lT7df+EbSC43xDboFg=";
    };
  };
in

stdenv.mkDerivation {
  pname = "pkl";
  inherit version;

  src =
    srcs.${stdenv.hostPlatform.system} or (throw "Unsupported platform: ${stdenv.hostPlatform.system}");

  nativeBuildInputs = [ makeWrapper ];

  dontUnpack = true;
  dontStrip = true;
  dontPatchELF = true;

  installPhase = ''
    runHook preInstall
    install -Dm755 $src $out/libexec/pkl
    runHook postInstall
  '';

  # GraalVM native images have a non-standard ELF layout that patchelf corrupts
  # when setting rpath. Patch only the interpreter, then wrap with LD_LIBRARY_PATH.
  postFixup = lib.optionalString stdenv.hostPlatform.isLinux ''
    patchelf --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" $out/libexec/pkl
    makeWrapper $out/libexec/pkl $out/bin/pkl \
      --prefix LD_LIBRARY_PATH : "${
        lib.makeLibraryPath [
          zlib
          stdenv.cc.cc.lib
        ]
      }"
  '';

  meta = {
    description = "Configuration language for generating static configuration";
    homepage = "https://pkl-lang.org/";
    license = lib.licenses.asl20;
    mainProgram = "pkl";
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
    ];
  };
}
