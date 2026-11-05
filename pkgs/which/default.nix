{
  lib,
  stdenv,
  fetchurl,
  runCommand,
  testers,
  directoryListingUpdater,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "which";
  version = "2.25";

  src = fetchurl {
    url = "mirror://gnu/which/which-${finalAttrs.version}.tar.gz";
    hash = "sha256-HLg+T3AuYLghGrXsTCr7qxsd7IAglFan0vr3WE7SJeo=";
  };

  # The bundled getopt.h declares `int getopt();`, which conflicts with the
  # SDK prototype under C23 (an empty parameter list means `void`).
  configureFlags = lib.optionals stdenv.hostPlatform.isDarwin [ "ac_cv_prog_cc_c23=no" ];

  passthru = {
    tests = {
      version = testers.testVersion {
        package = finalAttrs.finalPackage;
      };
      lookup = runCommand "which-test-lookup" { } ''
        ${finalAttrs.finalPackage}/bin/which which > $out
      '';
    };
    updateScript = directoryListingUpdater {
      inherit (finalAttrs) pname version;
      url = "https://ftp.gnu.org/gnu/which/";
    };
  };

  meta = {
    homepage = "https://www.gnu.org/software/which/";
    description = "Shows the full path of (shell) commands";
    license = lib.licenses.gpl3Plus;
    mainProgram = "which";
    platforms = lib.platforms.all;
  };
})
