{
  buildPerlPackage,
  ClassInspector,
  fetchurl,
  FileShareDirInstall,
  lib,
  stdenv,
}:

buildPerlPackage {
  pname = "File-ShareDir";
  version = "1.118";
  src = fetchurl {
    url = "mirror://cpan/authors/id/R/RE/REHSACK/File-ShareDir-1.118.tar.gz";
    hash = "sha256-O7KiC6Nd+VjcCk8jBvwF2QPYuMTePIvu/OF3OdKByVg=";
  };
  # Fix dynamic loading not available when cross compiling
  postPatch = lib.optionalString (stdenv.hostPlatform != stdenv.buildPlatform) ''
    sed -i '/install_share/d' Makefile.PL
    sed -i '/File::ShareDir::Install/d' Makefile.PL
  '';
  propagatedBuildInputs = [ ClassInspector ];
  buildInputs = [ FileShareDirInstall ];
  meta = {
    description = "Locate per-dist and per-module shared files";
  };
}
