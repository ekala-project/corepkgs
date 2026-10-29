{
  lib,
  stdenv,
  fetchurl,
  installShellFiles,
  pkg-config,
  libdatrie,
  testers,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "libthai";
  version = "0.1.30";

  outputs = [
    "out"
    "dev"
  ];

  src = fetchurl {
    url = "https://github.com/tlwg/libthai/releases/download/v${finalAttrs.version}/libthai-${finalAttrs.version}.tar.xz";
    sha256 = "sha256-3bqLU9/lhMMlN2YDAhioiCVIilGn3u8EHQlucVr2S90=";
  };

  nativeBuildInputs = [
    installShellFiles
    (lib.getBin libdatrie)
    pkg-config
  ];

  buildInputs = [ libdatrie ];

  postInstall = ''
    installManPage man/man3/*.3
  '';

  passthru.tests.testLink = testers.pkg-config.testLink { package = finalAttrs.finalPackage; };

  meta = {
    homepage = "https://linux.thai.net/projects/libthai/";
    description = "Set of Thai language support routines";
    license = lib.licenses.lgpl21Plus;
    platforms = lib.platforms.unix;
    pkgConfigModules = [ "libthai" ];
  };
})
