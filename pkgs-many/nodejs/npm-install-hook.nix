{
  lib,
  makeSetupHook,
  nodejs,
}:

makeSetupHook {
  name = "npm-install-hook";

  substitutions = {
    nodejsPath = "${nodejs}/bin/node";
  };

  meta = {
    description = "Setup hook for npm package installation";
  };
} ./npm-install-hook.sh
