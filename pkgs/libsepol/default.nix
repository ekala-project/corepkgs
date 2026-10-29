{
  lib,
  stdenv,
  fetchurl,
  flex,
  libselinux,
  testers,
}:

let
  se_url = "https://github.com/SELinuxProject/selinux/releases/download";
in
stdenv.mkDerivation (finalAttrs: {
  pname = "libsepol";
  version = "3.11";

  outputs = [
    "bin"
    "out"
    "dev"
    "man"
  ];

  src = fetchurl {
    url = "${se_url}/${finalAttrs.version}/libsepol-${finalAttrs.version}.tar.gz";
    sha256 = "sha256-efPSyI9Et+tc9U2XkuAyMil+F/l6F5Fj8nUAmaAPFk0=";
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

  passthru = {
    inherit se_url;
    tests = {
      inherit libselinux;
      testLink = testers.pkg-config.testLink { package = finalAttrs.finalPackage; };
    };
  };

  meta = {
    description = "SELinux binary policy manipulation library";
    homepage = "http://userspace.selinuxproject.org";
    platforms = lib.platforms.linux;
    license = lib.licenses.gpl2Plus;
    pkgConfigModules = [ "libsepol" ];
    identifiers.cpeParts = lib.meta.cpeFullVersionWithVendor "selinuxproject" finalAttrs.version;
  };
})
