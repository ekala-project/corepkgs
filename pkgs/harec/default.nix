# harec — Bootstrapping Hare compiler written in C
{
  lib,
  stdenv,
  fetchgit,
  qbe,
}:

let
  arch = stdenv.hostPlatform.uname.processor;
  platform = lib.toLower stdenv.hostPlatform.uname.system;
  qbePlatform =
    {
      x86_64 = "amd64_sysv";
      aarch64 = "arm64";
      riscv64 = "rv64";
    }
    .${arch};
in
stdenv.mkDerivation (finalAttrs: {
  pname = "harec";
  version = "0.26.0";

  src = fetchgit {
    url = "https://git.sr.ht/~sircmpwn/harec";
    rev = finalAttrs.version;
    hash = "sha256-azj37C+Uw8wqy0lf3g/kB353iufY6P7Rf20aLCRp9a8=";
  };

  nativeBuildInputs = [ qbe ];
  buildInputs = [ qbe ];

  makeFlags = [
    "PREFIX=${placeholder "out"}"
    "ARCH=${arch}"
    "VERSION=${finalAttrs.version}-nixpkgs"
    "QBEFLAGS=-t${qbePlatform}"
    "CC=${stdenv.cc.targetPrefix}cc"
    "AS=${stdenv.cc.targetPrefix}as"
    "LD=${stdenv.cc.targetPrefix}ld"
  ];

  strictDeps = true;
  enableParallelBuilding = true;

  postConfigure = ''
    ln -s configs/${platform}.mk config.mk
  '';

  meta = {
    description = "Bootstrapping Hare compiler written in C for POSIX systems";
    homepage = "https://harelang.org/";
    license = lib.licenses.gpl3Only;
    mainProgram = "harec";
    platforms = lib.platforms.linux;
  };
})
