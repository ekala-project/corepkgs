# pnpmConfigHook: Setup hook for configuring pnpm in build environments
#
# This hook configures pnpm to use pre-fetched dependencies during the build phase.
# It extracts the pnpm store from pnpmDeps and configures pnpm to use it.

{
  lib,
  stdenvNoCC,
  makeSetupHook,
  writableTmpDirAsHomeHook,
  zstd,
}:

makeSetupHook {
  name = "pnpm-config-hook";
  propagatedBuildInputs = [
    writableTmpDirAsHomeHook
    zstd
  ];
  substitutions = {
    npmArch = stdenvNoCC.targetPlatform.node.arch;
    npmPlatform = stdenvNoCC.targetPlatform.node.platform;
  };
  meta = {
    description = "Configuration hook for pnpm-based Node.js packages";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
  };
} ./pnpm-config-hook.sh
