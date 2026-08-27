{
  lib,
  stdenv,
  fetchFromGitLab,
  util-macros,
  autoreconfHook,
  pkg-config,
  libxcb,
  xorgproto,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "xcb-util-renderutil";
  version = "0.3.10";

  outputs = [
    "out"
    "dev"
  ];

  src = fetchFromGitLab {
    domain = "gitlab.freedesktop.org";
    group = "xorg";
    owner = "lib";
    repo = "libxcb-render-util";
    tag = "xcb-util-renderutil-${finalAttrs.version}";
    hash = "sha256-+QEQBkUVpVaYFKr6aN1VbkZj7wQHIGl4q6bh6l/Jo8I=";
  };

  strictDeps = true;

  nativeBuildInputs = [
    autoreconfHook
    pkg-config
    util-macros
  ];

  buildInputs = [
    libxcb
    xorgproto
  ];

  propagatedBuildInputs = [ libxcb ];

  meta = {
    description = "XCB convenience functions for the Render extension";
    homepage = "https://gitlab.freedesktop.org/xorg/lib/libxcb-render-util";
    license = with lib.licenses; [
      hpndSellVariant
      x11
    ];
    pkgConfigModules = [ "xcb-renderutil" ];
    platforms = lib.platforms.unix;
    identifiers.cpeParts = {
      vendor = "x.org";
      product = "xcb-util-renderutil";
    };
  };
})
