{
  lib,
  makeSetupHook,
  installShellFiles,
  jq,
}:

makeSetupHook {
  name = "nodejs-install-manuals";
  propagatedBuildInputs = [ installShellFiles ];
  substitutions = {
    jq = "${jq}/bin/jq";
  };
  meta = {
    description = "Setup hook for installing Node.js manual pages";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
  };
} ./hook.sh
