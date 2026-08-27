{
  lib,
  stdenv,
  fetchFromGitLab,
  util-macros,
  autoreconfHook,
  pkg-config,
  python3,
  testers,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "xcb-proto";
  version = "1.17.0";

  src = fetchFromGitLab {
    domain = "gitlab.freedesktop.org";
    group = "xorg";
    owner = "proto";
    repo = "xcbproto";
    tag = "xcb-proto-${finalAttrs.version}";
    hash = "sha256-5YSX8Z6wDYe7D5+QClgF/BlL+U94ojhra5kXhSjdM1k=";
  };

  strictDeps = true;

  nativeBuildInputs = [
    autoreconfHook
    pkg-config
    python3
    util-macros
  ];

  passthru = {
    tests.pkg-config = testers.testMetaPkgConfig finalAttrs.finalPackage;
  };

  meta = {
    description = "XML-XCB protocol descriptions used by libxcb for the X11 protocol & extensions";
    homepage = "https://gitlab.freedesktop.org/xorg/proto/xcbproto";
    license = lib.licenses.x11;
    pkgConfigModules = [ "xcb-proto" ];
    platforms = lib.platforms.unix;
  };
})
