{
  lib,
  stdenv,
  systemdLibs,
  libudev-zero,
}:
if lib.meta.availableOn stdenv.hostPlatform systemdLibs then systemdLibs else libudev-zero
