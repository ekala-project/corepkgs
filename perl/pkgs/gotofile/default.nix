{
  buildPerlPackage,
  fetchurl,
  Test2Suite,
}:

buildPerlPackage {
  pname = "goto-file";
  version = "0.005";
  src = fetchurl {
    url = "mirror://cpan/authors/id/E/EX/EXODIST/goto-file-0.005.tar.gz";
    hash = "sha256-xs3V7kps3L2/MU2SpPmYXbzfnkJYBIyudhJcBSqjH3c=";
  };
  buildInputs = [ Test2Suite ];
  meta = {
    description = "Stop parsing the current file and move on to a different one";
  };
}
