{
  stdenv,
  lib,
  fetchFromGitLab,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "hostname-debian";
  version = "3.25";

  outputs = [
    "out"
    "man"
  ];

  src = fetchFromGitLab {
    domain = "salsa.debian.org";
    owner = "meskes";
    repo = "hostname";
    tag = "debian/${finalAttrs.version}";
    hash = "sha256-Yq8P5bF/RRZnWuFW0y2u08oZrydAKfopOtbrwbeIu3w=";
  };

  makeFlags = [
    "prefix=${placeholder "out"}"
  ];

  meta = {
    changelog = "https://salsa.debian.org/meskes/hostname/-/blob/${finalAttrs.src.tag}/debian/changelog";
    description = "Utility to set/show the host name or domain name";
    homepage = "https://tracker.debian.org/pkg/hostname";
    license = lib.licenses.gpl2Plus;
    mainProgram = "hostname";
    platforms = lib.platforms.gnu;
  };
})
