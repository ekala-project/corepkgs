# hare — Systems programming language
{
  lib,
  stdenv,
  fetchgit,
  harec,
  qbe,
  scdoc,
  tzdata,
  mailcap,
  replaceVars,
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
  pname = "hare";
  version = "0.26.0.1";

  outputs = [
    "out"
    "man"
  ];

  src = fetchgit {
    url = "https://git.sr.ht/~sircmpwn/hare";
    rev = finalAttrs.version;
    hash = "sha256-ypu3GXO2hTGg26l0+FUzEMK/+HiylJIWQxe9UbhKXz4=";
  };

  patches = [
    (replaceVars ./001-tzdata.patch {
      inherit tzdata;
    })
    ./002-dont-build-haredoc.patch
    (replaceVars ./003-hardcode-qbe-and-harec.patch {
      harec_bin = lib.getExe harec;
      qbe_bin = lib.getExe qbe;
    })
    (replaceVars ./004-use-mailcap-for-mimetypes.patch {
      inherit mailcap;
    })
  ];

  nativeBuildInputs = [
    harec
    qbe
    scdoc
  ];

  buildInputs = [
    harec
    qbe
  ];

  makeFlags = [
    "HARECACHE=.harecache"
    "PREFIX=${placeholder "out"}"
    "ARCH=${arch}"
    "VERSION=${finalAttrs.version}-nixpkgs"
    "QBEFLAGS=-t${qbePlatform}"
    "AS=${stdenv.cc.targetPrefix}as"
    "LD=${stdenv.cc.targetPrefix}ld"
    "HAREPATH=$(SRCDIR)/hare/stdlib"
  ];

  enableParallelBuilding = true;
  strictDeps = true;

  postConfigure = ''
    ln -s configs/${platform}.mk config.mk
  '';

  meta = {
    description = "Systems programming language designed to be simple, stable, and robust";
    homepage = "https://harelang.org/";
    license = lib.licenses.gpl3Only;
    mainProgram = "hare";
    platforms = lib.platforms.linux;
  };
})
