# buildXorgPackage — wrapper around stdenv.mkDerivation for X.org components.
#
# Centralizes the shared boilerplate from the xorg generated package set:
#   - Uses the xorg builder.sh (auto-propagates pkgconfig Requires)
#   - Disables bindnow and relro hardening (standard for xorg)
#   - Sets strictDeps = true
#   - Adds passthru.tests.pkg-config from testers
{
  lib,
  stdenv,
  testers,
}:

lib.extendMkDerivation {
  constructDrv = stdenv.mkDerivation;

  extendDrvArgs =
    finalAttrs:
    {
      meta ? { },
      ...
    }:
    {
      builder = ./builder.sh;

      hardeningDisable = [
        "bindnow"
        "relro"
      ];

      strictDeps = true;

      passthru.tests.pkg-config = testers.testMetaPkgConfig finalAttrs.finalPackage;

      meta = {
        platforms = lib.platforms.unix;
      }
      // meta;
    };
}
