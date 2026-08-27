{
  lib,
  stdenv,
  fetchFromGitLab,
  util-macros,
  autoreconfHook,
  pkg-config,
  libx11,
  libxau,
  libxext,
  libxmu,
  xorgproto,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "xauth";
  version = "1.1.5";

  src = fetchFromGitLab {
    domain = "gitlab.freedesktop.org";
    group = "xorg";
    owner = "app";
    repo = "xauth";
    tag = "xauth-${finalAttrs.version}";
    hash = "sha256-FQCtdS6GyeDeOZvA2jXtr63wY5DIC7Wnjy6hem7aw3w=";
  };

  strictDeps = true;

  nativeBuildInputs = [
    autoreconfHook
    pkg-config
    util-macros
  ];

  buildInputs = [
    libx11
    libxau
    libxext
    libxmu
    xorgproto
  ];

  meta = {
    description = "X authority file utility";
    longDescription = ''
      The xauth program is used to edit and display the authorization information used in connecting
      to the X server.
    '';
    homepage = "https://gitlab.freedesktop.org/xorg/app/xauth";
    license = lib.licenses.mitOpenGroup;
    mainProgram = "xauth";
    platforms = lib.platforms.unix;
  };
})
