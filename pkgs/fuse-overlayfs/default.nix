{
  lib,
  stdenv,
  fetchFromGitHub,
  autoreconfHook,
  pkg-config,
  fuse3,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "fuse-overlayfs";
  version = "1.17";

  src = fetchFromGitHub {
    owner = "containers";
    repo = "fuse-overlayfs";
    rev = "v${finalAttrs.version}";
    hash = "sha256-oXSqyxe5+hsuFXKajuviqh2nKIz8Kw6rjLnb6XTF6GI=";
  };

  nativeBuildInputs = [
    autoreconfHook
    pkg-config
  ];

  buildInputs = [ fuse3 ];

  enableParallelBuilding = true;
  strictDeps = true;

  outputs = [
    "out"
    "man"
  ];

  passthru.tests = { };

  meta = {
    description = "FUSE implementation for overlayfs";
    longDescription = "An implementation of overlay+shiftfs in FUSE for rootless containers.";
    license = lib.licenses.gpl3;
    maintainers = [ ];
    platforms = lib.platforms.linux;
    inherit (finalAttrs.src.meta) homepage;
    mainProgram = "fuse-overlayfs";
  };
})
