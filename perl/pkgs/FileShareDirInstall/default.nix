{
  buildPerlPackage,
  fetchurl,
}:

buildPerlPackage {
  pname = "File-ShareDir-Install";
  version = "0.14";
  src = fetchurl {
    url = "mirror://cpan/authors/id/E/ET/ETHER/File-ShareDir-Install-0.14.tar.gz";
    hash = "sha256-j5UzsZjy1KmlKIy8fSJPdnmtBaeoVzdFWZeJQovFrqA=";
  };
  meta = {
    description = "Install shared files";
    homepage = "https://github.com/Perl-Toolchain-Gang/File-ShareDir-Install";
  };
}
