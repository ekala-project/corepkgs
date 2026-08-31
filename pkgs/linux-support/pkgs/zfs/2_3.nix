{
  callPackage,
  lib,
  stdenv,
  ...
}@args:

callPackage ./generic.nix args {
  # You have to ensure that in `pkgs/top-level/linux-kernels.nix`
  # this attribute is the correct one for this package.
  kernelModuleAttribute = "zfs_2_3";

  kernelMinSupportedMajorMinor = "4.18";
  kernelMaxSupportedMajorMinor = "7.2";

  # this package should point to the latest release.
  version = "2.3.9";

  tests = { };

  hash = "sha256-LXyicM8neU06Z8Bq0ukZPkJ1ZfAcr2r2YojPfUVpj3k=";
}
