{
  stdenv,
  lib,
  perl,
  pkg-config,
  curl,
  nix,
  libsodium,
  boost,
  autoreconfHook,
  autoconf-archive,
  xz,
  meson,
  ninja,
  bzip2,
  libarchive,
}:

let
  atLeast223 = lib.versionAtLeast nix.version "2.23";
  atLeast224 = lib.versionAtLeast nix.version "2.24";
  atLeast226 = lib.versionAtLeast nix.version "2.26";
in
stdenv.mkDerivation (finalAttrs: {
  pname = "nix-perl";
  inherit (nix) version src;

  postUnpack = "sourceRoot=$sourceRoot/${lib.optionalString atLeast224 "src"}/perl";

  # TODO: Remove this once the nix build also uses meson
  postPatch = lib.optionalString (atLeast224 && lib.versionOlder nix.version "2.27") ''
    substituteInPlace lib/Nix/Store.xs \
      --replace-fail 'config-util.hh' 'nix/config.h' \
      --replace-fail 'config-store.hh' 'nix/config.h'
  '';

  buildInputs = [
    boost
    bzip2
    curl
    libsodium
    nix
    perl
    xz
  ]
  ++ lib.optional atLeast226 libarchive;

  # Not cross-safe since Nix checks for curl/perl via
  # NEED_PROG/find_program, but both seem to be needed at runtime
  # as well.
  nativeBuildInputs = [
    pkg-config
    perl
    curl
  ]
  ++ (
    if atLeast223 then
      [
        meson
        ninja
      ]
    else
      [
        autoconf-archive
        autoreconfHook
      ]
  );

  # `perlPackages.Test2Harness` is marked broken for Darwin
  doCheck = !stdenv.hostPlatform.isDarwin;

  nativeCheckInputs = [
    perl.pkgs.Test2Harness
  ];

  mesonEntries = lib.optionalAttrs atLeast223 {
    dbi_path = "${perl.pkgs.DBI}/${perl.libPrefix}";
    dbd_sqlite_path = "${perl.pkgs.DBDSQLite}/${perl.libPrefix}";
    tests = if finalAttrs.finalPackage.doCheck then "enabled" else "disabled";
  };

  configureFlags = lib.optionals (!atLeast223) [
    (lib.withFeatureAs true "dbi" "${perl.pkgs.DBI}/${perl.libPrefix}")
    (lib.withFeatureAs true "dbd-sqlite" "${perl.pkgs.DBDSQLite}/${perl.libPrefix}")
  ];

  preConfigure = "export NIX_STATE_DIR=$TMPDIR";

  passthru = { inherit perl; };
})
