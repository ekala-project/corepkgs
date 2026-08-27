{
  lib,
  stdenv,
  fetchurl,
  pkg-config,
  libx11,
  libxext,
  xorgproto,
  writeScript,
  testers,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "libxxf86vm";
  version = "1.1.5";

  outputs = [
    "out"
    "dev"
  ];

  src = fetchurl {
    url = "mirror://xorg/individual/lib/libXxf86vm-${finalAttrs.version}.tar.xz";
    hash = "sha256-JH/vSLPg5+ZxKeQfHniejQBrpH26HAzc5oS5twP4iOc=";
  };

  strictDeps = true;

  nativeBuildInputs = [ pkg-config ];

  buildInputs = [
    libx11
    libxext
    xorgproto
  ];

  propagatedBuildInputs = [
    xorgproto
    libx11
    libxext
  ];

  configureFlags = lib.optional (
    stdenv.hostPlatform != stdenv.buildPlatform
  ) "--enable-malloc0returnsnull";

  passthru = {
    updateScript = writeScript "update-${finalAttrs.pname}" ''
      #!/usr/bin/env nix-shell
      #!nix-shell -i bash -p common-updater-scripts
      version="$(list-directory-versions --pname libXxf86vm \
        --url https://xorg.freedesktop.org/releases/individual/lib/ \
        | sort -V | tail -n1)"
      update-source-version ${finalAttrs.pname} "$version"
    '';
    tests.pkg-config = testers.testMetaPkgConfig finalAttrs.finalPackage;
  };

  meta = {
    description = "Xlib-based library for the XFree86-VidMode X extension";
    homepage = "https://gitlab.freedesktop.org/xorg/lib/libxxf86vm";
    license = lib.licenses.mit;
    pkgConfigModules = [ "xxf86vm" ];
    maintainers = [ ];
    platforms = lib.platforms.unix;
  };
})
