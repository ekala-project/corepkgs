{
  lib,
  makeSetupHook,
  installShellFiles,
  makeWrapper,
  nodejs,
  jq,
}:

makeSetupHook {
  name = "nodejs-install-executables";
  propagatedBuildInputs = [
    installShellFiles
    makeWrapper
  ];
  substitutions = {
    hostNode = "${nodejs}/bin/node";
    jq = "${jq}/bin/jq";
  };
  meta = {
    description = "Setup hook for installing Node.js executables";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
  };
} ./hook.sh
