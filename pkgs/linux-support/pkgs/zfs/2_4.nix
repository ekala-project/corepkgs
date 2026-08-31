{
  callPackage,
  lib,
  stdenv,
  ...
}@args:

callPackage ./generic.nix args {
  # You have to ensure that in `pkgs/top-level/linux-kernels.nix`
  # this attribute is the correct one for this package.
  kernelModuleAttribute = "zfs_2_4";

  kernelMinSupportedMajorMinor = "4.18";
  kernelMaxSupportedMajorMinor = "7.2";

  # this package should point to the latest release.
  version = "2.4.4";

  tests = { };

  hash = "sha256-Ps6xc3pLpemZE7fSE1RKIUb5on1fEPOlLZAknDlgZbY=";
}
