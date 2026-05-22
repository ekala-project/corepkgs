{
  lib,
  stdenv,
  fetchurl,
  flex,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "libsepol";
  version = "3.8.1";
  se_url = "https://github.com/SELinuxProject/selinux/releases/download";

  outputs = [
    "bin"
    "out"
    "dev"
    "man"
  ];

  src = fetchurl {
    url = "${finalAttrs.se_url}/${finalAttrs.version}/libsepol-${finalAttrs.version}.tar.gz";
    sha256 = "sha256-DnhwUwX5VavUwGVNN6VHfuJjSat0254rA6eGiJeuHd8=";
  };

  postPatch = lib.optionalString stdenv.hostPlatform.isStatic ''
    substituteInPlace src/Makefile --replace 'all: $(LIBA) $(LIBSO)' 'all: $(LIBA)'
    sed -i $'/^\t.*LIBSO/d' src/Makefile
  '';

  nativeBuildInputs = [ flex ];

  makeFlags = [
    "PREFIX=$(out)"
    "BINDIR=$(bin)/bin"
    "INCDIR=$(dev)/include/sepol"
    "INCLUDEDIR=$(dev)/include"
    "MAN3DIR=$(man)/share/man/man3"
    "MAN8DIR=$(man)/share/man/man8"
    "SHLIBDIR=$(out)/lib"
  ];

  env.NIX_CFLAGS_COMPILE = "-Wno-error";

  enableParallelBuilding = true;

  doCheck = false;

  passthru = {
    inherit (finalAttrs) se_url;
    tests.unit = finalAttrs.finalPackage.overrideAttrs { doCheck = true; };
  };

  meta = {
    description = "SELinux binary policy manipulation library";
    homepage = "http://userspace.selinuxproject.org";
    platforms = lib.platforms.linux;
    license = lib.licenses.gpl2Plus;
    pkgConfigModules = [ "libselinux" ];
  };
})
