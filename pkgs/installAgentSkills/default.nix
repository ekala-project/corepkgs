{
  lib,
  callPackage,
  makeSetupHook,
}:

# See the header comment in ./setup-hook.sh for example usage.
makeSetupHook {
  name = "install-agent-skills";
  passthru = {
    tests = lib.packagesFromDirectoryRecursive {
      inherit callPackage;
      directory = ./tests;
    };
  };
  meta = {
    description = "Setup hook for installing agent skills into the correct directories";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
  };
} ./setup-hook.sh
