{
  lib,
  stdenv,
  fetchFromGitLab,
  util-macros,
  autoreconfHook,
  pkg-config,
  xorgproto,
  testers,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "libxau";
  version = "1.0.12";

  outputs = [
    "out"
    "dev"
  ];

  src = fetchFromGitLab {
    domain = "gitlab.freedesktop.org";
    group = "xorg";
    owner = "lib";
    repo = "libxau";
    tag = "libXau-${finalAttrs.version}";
    hash = "sha256-zSj0btY9hz/OWTpzqVP+cHWDqKrBL4UkexOwp8B+OXU=";
  };

  strictDeps = true;
  nativeBuildInputs = [
    autoreconfHook
    pkg-config
    util-macros
  ];
  propagatedBuildInputs = [ xorgproto ];

  passthru = {
    tests.pkg-config = testers.testMetaPkgConfig finalAttrs.finalPackage;
  };

  meta = {
    description = "Functions for handling Xauthority files and entries.";
    homepage = "https://gitlab.freedesktop.org/xorg/lib/libxau";
    license = lib.licenses.mitOpenGroup;
    pkgConfigModules = [ "xau" ];
    platforms = lib.platforms.unix;
    identifiers.cpeParts = lib.meta.cpeFullVersionWithVendor "x.org" finalAttrs.version;
  };
})
