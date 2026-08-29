{
  buildPerlPackage,
  fetchurl,
  PathTiny,
  TestDeep,
  TestFatal,
  TestFile,
  TestWarnings,
}:

buildPerlPackage {
  pname = "File-Copy-Recursive";
  version = "0.45";
  src = fetchurl {
    url = "mirror://cpan/authors/id/D/DM/DMUEY/File-Copy-Recursive-0.45.tar.gz";
    hash = "sha256-05cc94qDReOAQrIIu3s5y2lQgDhq9in0oE/9ZUnfEVc=";
  };
  buildInputs = [
    PathTiny
    TestDeep
    TestFatal
    TestFile
    TestWarnings
  ];
  meta = {
    description = "Perl extension for recursively copying files and directories";
  };
}
