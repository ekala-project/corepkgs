{
  lib,
  makeSetupHook,
  gnu-config,
}:

makeSetupHook {
  name = "update-autotools-gnu-config-scripts-hook";
  substitutions = {
    gnu_config = gnu-config;
  };
  meta = {
    description = "Setup hook for updating GNU config scripts";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
  };
} ./update-autotools-gnu-config-scripts.sh
