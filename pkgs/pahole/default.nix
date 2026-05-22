{
  lib,
  stdenv,
  fetchzip,
  pkg-config,
  libbpf,
  cmake,
  elfutils,
  zlib,
  argp-standalone,
  musl-obstack,

  nixosTests,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "pahole";
  version = "1.30";
  src = fetchzip {
    url = "https://git.kernel.org/pub/scm/devel/pahole/pahole.git/snapshot/pahole-${finalAttrs.version}.tar.gz";
    hash = "sha256-JF4KnI05uOlPuunJuetX/fX3ZRT6TDXdjCNG9/ufkgI=";
  };

  nativeBuildInputs = [
    cmake
    cmake.configurePhaseHook
    pkg-config
  ];
  buildInputs = [
    elfutils
    zlib
    libbpf
  ]
  ++ lib.optionals stdenv.hostPlatform.isMusl [
    argp-standalone
    musl-obstack
  ];

  # Put libraries in "lib" subdirectory, not top level of $out
  cmakeFlags = [
    "-DCMAKE_INSTALL_LIBDIR=lib"
    "-DLIBBPF_EMBEDDED=OFF"
  ];

  doCheck = false;

  passthru.tests = {
    unit = finalAttrs.finalPackage.overrideAttrs { doCheck = true; };
    inherit (nixosTests) bpf;
  };

  meta = {
    homepage = "https://git.kernel.org/pub/scm/devel/pahole/pahole.git/";
    description = "Shows, manipulates, and pretty-prints debugging information in DWARF, CTF, and BTF formats";
    license = lib.licenses.gpl2Only;
    platforms = lib.platforms.linux;
  };
})
