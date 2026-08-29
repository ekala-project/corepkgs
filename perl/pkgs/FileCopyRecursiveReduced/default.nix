{
  buildPerlPackage,
  CaptureTiny,
  fetchurl,
  PathTiny,
}:

buildPerlPackage {
  pname = "File-Copy-Recursive-Reduced";
  version = "0.007";
  src = fetchurl {
    url = "mirror://cpan/authors/id/J/JK/JKEENAN/File-Copy-Recursive-Reduced-0.007.tar.gz";
    hash = "sha256-07WFIuaYA6kUN+KcCZ63Bug3Px7vBRik3DZp3T383Cc=";
  };
  buildInputs = [
    CaptureTiny
    PathTiny
  ];
  meta = {
    description = "Recursive copying of files and directories within Perl 5 toolchain";
    homepage = "http://thenceforward.net/perl/modules/File-Copy-Recursive-Reduced";
  };
}
