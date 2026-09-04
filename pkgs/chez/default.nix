{
  lib,
  stdenv,
  fetchFromGitHub,
  zuo,
  zlib,
  lz4,
  libffi,
  ncurses,
  libiconv,
  libx11,
  buildPackages,
}:

let
  inherit (stdenv.hostPlatform) extensions;
in

stdenv.mkDerivation (finalAttrs: {
  pname = "chez-scheme";
  version = "10.4.1";

  src = fetchFromGitHub {
    owner = "cisco";
    repo = "ChezScheme";
    tag = "v${finalAttrs.version}";
    hash = "sha256-7b7I+g4h05BRI2lLAlwlIBw5KxKAai1lU8TESACaSYg=";
    fetchSubmodules = true;
  };

  strictDeps = true;
  depsBuildBuild = [ zuo ];

  buildInputs = [
    ncurses
    libiconv
    zlib
    lz4
    libffi
  ]
  ++ lib.optionals stdenv.hostPlatform.isUnix [
    libx11
  ];

  enableParallelBuilding = true;
  dontAddPrefix = true;
  configurePlatforms = [ ];
  configureFlags = [
    "--as-is"
    "--threads"
    "--installprefix=${placeholder "out"}"
    "--installman=${placeholder "out"}/share/man"
    "--installabsolute"
    "--enable-libffi"
    "CC_FOR_BUILD=${lib.getExe buildPackages.stdenv.cc}"
    "ZUO=zuo"
    "ZLIB=${zlib}/lib/libz${extensions.sharedLibrary}"
    "LZ4=${lz4.lib}/lib/liblz4${extensions.sharedLibrary}"
    "CFLAGS+=${lib.optionalString stdenv.cc.isGNU "-Wno-error=format-truncation"}"
  ];

  postInstall = ''
    rm -rf $out/lib/csv${finalAttrs.version}/examples
  '';

  setupHook = ./setup-hook.sh;

  doInstallCheck = true;
  installCheckPhase = ''
    echo "(exit)" | "$out/bin/scheme"
  '';

  meta = {
    description = "Powerful and incredibly fast R6RS Scheme compiler";
    homepage = "https://cisco.github.io/ChezScheme/";
    license = lib.licenses.asl20;
    platforms = lib.platforms.all;
    mainProgram = "scheme";
  };
})
