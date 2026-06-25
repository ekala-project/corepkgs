{
  lib,
  stdenv,
  makeSetupHook,
}:

makeSetupHook {
  name = "add-driver-runpath-hook";

  substitutions = {
    driverLink = "/run/opengl-driver" + lib.optionalString stdenv.hostPlatform.isi686 "-32";
  };

  passthru = {
    driverLink = "/run/opengl-driver" + lib.optionalString stdenv.hostPlatform.isi686 "-32";
  };

  meta.license = lib.licenses.mit;
} ./setup-hook.sh
