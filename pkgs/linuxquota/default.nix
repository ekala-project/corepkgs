{
  lib,
  stdenv,
  fetchurl,
  e2fsprogs,
  openldap,
  pkg-config,
  binlore,
  linuxquota,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "quota";
  version = "4.11";

  src = fetchurl {
    url = "mirror://sourceforge/linuxquota/quota-${finalAttrs.version}.tar.gz";
    hash = "sha256-ClG4+SAlTY6Dw0pMMIK30kH11v1lGIr63ymFnVIj73g=";
  };

  outputs = [
    "out"
    "dev"
    "doc"
    "man"
  ];

  nativeBuildInputs = [ pkg-config ];
  buildInputs = [
    e2fsprogs
    openldap
  ];

  passthru.binlore.out = binlore.synthesize linuxquota ''
    execer cannot bin/quota
  '';

  meta = {
    description = "Tools to manage kernel-level quotas in Linux";
    homepage = "https://sourceforge.net/projects/linuxquota/";
    license = lib.licenses.gpl2Plus;
    platforms = lib.platforms.linux;
  };
})
