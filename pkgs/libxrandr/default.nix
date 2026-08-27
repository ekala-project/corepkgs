{
  lib,
  stdenv,
  fetchurl,
  pkg-config,
  libx11,
  libxext,
  libxrender,
  libxfixes,
  xorgproto,
  writeScript,
  testers,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "libxrandr";
  version = "1.5.4";

  outputs = [
    "out"
    "dev"
    "man"
  ];

  src = fetchurl {
    url = "mirror://xorg/individual/lib/libXrandr-${finalAttrs.version}.tar.xz";
    hash = "sha256-GtWwZTdfSoWRWqYGEcxkB8BgSSohTX+dryFL51LDtNM=";
  };

  strictDeps = true;

  nativeBuildInputs = [ pkg-config ];

  buildInputs = [
    libx11
    libxext
    libxrender
    libxfixes
    xorgproto
  ];

  propagatedBuildInputs = [
    xorgproto
    libx11
    libxext
    libxrender
    libxfixes
  ];

  configureFlags = lib.optional (
    stdenv.hostPlatform != stdenv.buildPlatform
  ) "--enable-malloc0returnsnull";

  passthru = {
    updateScript = writeScript "update-${finalAttrs.pname}" ''
      #!/usr/bin/env nix-shell
      #!nix-shell -i bash -p common-updater-scripts
      version="$(list-directory-versions --pname libXrandr \
        --url https://xorg.freedesktop.org/releases/individual/lib/ \
        | sort -V | tail -n1)"
      update-source-version ${finalAttrs.pname} "$version"
    '';
    tests.pkg-config = testers.testMetaPkgConfig finalAttrs.finalPackage;
  };

  meta = {
    description = "Xlib library for the X Resize, Rotate, and Reflect Extension";
    homepage = "https://gitlab.freedesktop.org/xorg/lib/libxrandr";
    license = lib.licenses.mit;
    pkgConfigModules = [ "xrandr" ];
    platforms = lib.platforms.unix;
    identifiers.cpeParts = lib.meta.cpeFullVersionWithVendor "x.org" finalAttrs.version;
  };
})
