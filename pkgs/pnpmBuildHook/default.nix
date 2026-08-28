{
  lib,
  makeSetupHook,
}:
makeSetupHook {
  name = "pnpm-build-hook";
  meta = {
    description = "Build hook for pnpm-based Node.js packages";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
  };
} ./pnpm-build-hook.sh
