# libb2 — BLAKE2 cryptographic hash function library
{
  lib,
  stdenv,
  fetchFromGitHub,
  autoreconfHook,
  libtool,
  pkg-config,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "libb2";
  version = "0.98.1";

  src = fetchFromGitHub {
    owner = "BLAKE2";
    repo = "libb2";
    tag = "v${finalAttrs.version}";
    sha256 = "0qj8aaqvfcavj1vj5asm4pqm03ap7q8x4c2fy83cqggvky0frgya";
  };

  nativeBuildInputs = [
    autoreconfHook
    libtool
    pkg-config
  ];

  configureFlags = lib.optional stdenv.hostPlatform.isx86 "--enable-fat=yes";

  enableParallelBuilding = true;

  meta = {
    description = "BLAKE2 family of cryptographic hash functions";
    homepage = "https://blake2.net/";
    license = lib.licenses.cc0;
    platforms = lib.platforms.all;
  };
})
