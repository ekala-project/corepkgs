{
  lib,
  callPackage,
  makeSetupHook,
}:

# See the header comment in ./setup-hook.sh for example usage.
makeSetupHook {
  name = "install-shell-files";
  passthru = {
    tests = lib.packagesFromDirectoryRecursive {
      inherit callPackage;
      directory = ./tests;
    };
  };
  meta = {
    description = "Setup hook for installing shell completion files and man pages";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
  };
} ./setup-hook.sh
