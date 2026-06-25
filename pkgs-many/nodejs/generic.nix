{
  version,
  src-hash,
  ...
}:

{
  lib,
  stdenv,
  fetchurl,
  python3,
  python312,
  which,
  icu,
  libuv,
  nghttp2,
  openssl,
  zlib,
  c-ares,
  brotli,
  pkg-config,
  callPackage,
}:

let
  majorVersion = lib.versions.major version;
  minorVersion = lib.versions.majorMinor version;
  # Node.js 18 and 20 require Python 3.12 or older
  # Node.js 22+ works with Python 3.13
  python = if (lib.versionAtLeast version "22.0") then python3 else python312;
in
stdenv.mkDerivation (finalAttrs: {
  pname = "nodejs";
  inherit version;

  src = fetchurl {
    url = "https://nodejs.org/dist/v${version}/node-v${version}.tar.xz";
    hash = src-hash;
  };

  nativeBuildInputs = [
    python
    which
    pkg-config
  ];

  buildInputs = [
    icu
    libuv
    nghttp2
    openssl
    zlib
    c-ares
    brotli
  ];

  configureFlags = [
    "--shared-openssl"
    "--shared-zlib"
    "--shared-libuv"
    "--shared-nghttp2"
    "--shared-cares"
    "--shared-brotli"
    "--with-intl=system-icu"
  ];

  enableParallelBuilding = true;

  # Node.js build can be memory intensive
  env.NIX_CFLAGS_COMPILE = lib.optionalString stdenv.cc.isClang "-Wno-error=unused-command-line-argument";

  # Ensure ICU libraries are linked properly
  env.NIX_LDFLAGS = "-licuuc -licudata";

  postInstall = ''
    # Remove unnecessary files
    rm -rf $out/include/node/openssl

    # Create version-specific symlinks
    ln -s $out/bin/node $out/bin/nodejs || true

    # Install npm in the same output
    # npm is bundled with Node.js source
    export HOST_PATH="$out/bin:$PATH"
    patchShebangs --host $out/bin/*
  '';

  passthru = {
    python = python;
    inherit python3;
    majorVersion = majorVersion;
    minorVersion = minorVersion;
    npmInstallHook = callPackage ./npm-install-hook.nix {
      nodejs = finalAttrs.finalPackage;
    };
    buildNpmPackage = callPackage ./build-npm-package.nix {
      nodejs = finalAttrs.finalPackage;
    };
    buildNpmApplication = callPackage ./build-npm-application.nix {
      nodejs = finalAttrs.finalPackage;
    };
  };

  meta = {
    description = "JavaScript runtime built on Chrome's V8 JavaScript engine";
    homepage = "https://nodejs.org/";
    changelog = "https://github.com/nodejs/node/releases/tag/v${version}";
    license = lib.licenses.mit;
    platforms = lib.platforms.unix ++ lib.platforms.darwin;
    mainProgram = "node";
    maintainers = [ ];
  };
})
