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
  pname = "libxdmcp";
  version = "1.1.5";

  outputs = [
    "out"
    "dev"
    "doc"
  ];

  src = fetchFromGitLab {
    domain = "gitlab.freedesktop.org";
    group = "xorg";
    owner = "lib";
    repo = "libxdmcp";
    tag = "libXdmcp-${finalAttrs.version}";
    hash = "sha256-ko1hbQBht2UrimB1X3h4DyPWxeXFxHpCztWTsw/FtlA=";
  };

  strictDeps = true;

  nativeBuildInputs = [
    autoreconfHook
    pkg-config
    util-macros
  ];
  buildInputs = [ xorgproto ];

  passthru = {
    tests.pkg-config = testers.testMetaPkgConfig finalAttrs.finalPackage;
  };

  meta = {
    description = "X Display Manager Control Protocol library";
    homepage = "https://gitlab.freedesktop.org/xorg/lib/libxdmcp";
    license = lib.licenses.mitOpenGroup;
    pkgConfigModules = [ "xdmcp" ];
    platforms = lib.platforms.unix;
    identifiers.cpeParts = lib.meta.cpeFullVersionWithVendor "x.org" finalAttrs.version;
  };
})
