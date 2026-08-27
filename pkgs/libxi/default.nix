{
  lib,
  stdenv,
  fetchurl,
  pkg-config,
  libx11,
  libxext,
  libxfixes,
  xorgproto,
  writeScript,
  testers,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "libxi";
  version = "1.8.2";

  outputs = [
    "out"
    "dev"
    "man"
    "doc"
  ];

  src = fetchurl {
    url = "mirror://xorg/individual/lib/libXi-${finalAttrs.version}.tar.xz";
    hash = "sha256-0OBVXlPW4hFOq/pEImuhYtJwhQGiXhjZnPs1wJTGwQQ=";
  };

  strictDeps = true;

  nativeBuildInputs = [ pkg-config ];

  buildInputs = [
    libx11
    libxext
    libxfixes
    xorgproto
  ];

  propagatedBuildInputs = [
    xorgproto
    libx11
    libxext
    libxfixes
  ];

  configureFlags = lib.optional (
    stdenv.hostPlatform != stdenv.buildPlatform
  ) "--enable-malloc0returnsnull";

  passthru = {
    updateScript = writeScript "update-${finalAttrs.pname}" ''
      #!/usr/bin/env nix-shell
      #!nix-shell -i bash -p common-updater-scripts
      version="$(list-directory-versions --pname libXi \
        --url https://xorg.freedesktop.org/releases/individual/lib/ \
        | sort -V | tail -n1)"
      update-source-version ${finalAttrs.pname} "$version"
    '';
    tests.pkg-config = testers.testMetaPkgConfig finalAttrs.finalPackage;
  };

  meta = {
    description = "Xlib library for the X Input Extension";
    homepage = "https://gitlab.freedesktop.org/xorg/lib/libxi";
    license = lib.licenses.mit;
    pkgConfigModules = [ "xi" ];
    maintainers = [ ];
    platforms = lib.platforms.unix;
  };
})
