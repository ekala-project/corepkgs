{
  lib,
  stdenv,
  mkMesonDerivation,
  pkg-config,
  perl,
  perlPackages,
  nix-store,
  version,
  curl,
  bzip2,
  libsodium,
}:

perl.pkgs.toPerlModule (
  mkMesonDerivation (finalAttrs: {
    pname = "nix-perl";
    inherit version;

    workDir = ./.;

    nativeBuildInputs = [
      pkg-config
      perl
      curl
    ];

    buildInputs = [
      nix-store
      bzip2
      libsodium
    ];

    # `perlPackages.Test2Harness` is marked broken for Darwin
    doCheck = !stdenv.hostPlatform.isDarwin;

    nativeCheckInputs = [
      perlPackages.Test2Harness
    ];

    preConfigure =
      # "Inline" .version so its not a symlink, and includes the suffix
      ''
        chmod u+w .version
        echo ${finalAttrs.version} > .version
      '';

    mesonFeatures = {
      tests = finalAttrs.finalPackage.doCheck;
    };

    mesonEntries = {
      dbi_path = "${perlPackages.DBI}/${perl.libPrefix}";
      dbd_sqlite_path = "${perlPackages.DBDSQLite}/${perl.libPrefix}";
    };

    mesonCheckFlags = [
      "--print-errorlogs"
    ];

    strictDeps = false;
  })
)
