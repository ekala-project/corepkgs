{
  buildPackages,
  buildPerlPackage,
  fetchurl,
  lib,
  pkg-config,
  stdenv,
}:

buildPerlPackage {
  pname = "ExtUtils-PkgConfig";
  version = "1.16";
  src = fetchurl {
    url = "mirror://cpan/authors/id/X/XA/XAOC/ExtUtils-PkgConfig-1.16.tar.gz";
    hash = "sha256-u+rO2ZXX2NEM/FGjpaZtpBzrK8BP7cq1DhDmMA6AHG4=";
  };
  nativeBuildInputs = [ buildPackages.pkg-config ];
  propagatedNativeBuildInputs = [ pkg-config ];
  postPatch = ''
    # no pkg-config binary when cross-compiling so the check fails
    substituteInPlace Makefile.PL \
      --replace "pkg-config" "$PKG_CONFIG"
    # use correctly prefixed pkg-config binary
    substituteInPlace lib/ExtUtils/PkgConfig.pm \
      --replace-fail '`pkg-config' '`${stdenv.cc.targetPrefix}pkg-config' \
      --replace-fail '"pkg-config' '"${stdenv.cc.targetPrefix}pkg-config' \
      --replace-fail '/pkg-config' '/${stdenv.cc.targetPrefix}pkg-config'
  '';
  doCheck = false; # expects test_glib-2.0.pc in PKG_CONFIG_PATH
  meta = {
    description = "Simplistic interface to pkg-config";
    homepage = "https://gitlab.gnome.org/GNOME/perl-extutils-pkgconfig";
    license = with lib.licenses; [ lgpl21Plus ];

  };
}
