{
  lib,
  stdenv,
  fetchurl,
  testers,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "pkgconf";
  version = "2.4.3";

  src = fetchurl {
    url = "https://distfiles.ariadne.space/pkgconf/pkgconf-${finalAttrs.version}.tar.xz";
    hash = "sha256-eAvDEjylsqHaI5sBUC3q1GPVrEy/b8eLB9qtSNYcZPo=";
  };

  outputs = [
    "out"
    "man"
    "dev"
    "doc"
  ];
  strictDeps = true;

  enableParallelBuilding = true;

  # pkgconf ships its own pkg-config compatibility, install it
  postInstall = ''
    ln -s pkgconf "$out/bin/pkg-config"
  '';

  passthru.tests.version = testers.testVersion {
    package = finalAttrs.finalPackage;
  };

  meta = {
    description = "Package compiler and linker metadata toolkit";
    homepage = "https://gitea.treesitter.net/ariadne/pkgconf";
    license = lib.licenses.isc;
    platforms = lib.platforms.all;
    mainProgram = "pkgconf";
  };
})
