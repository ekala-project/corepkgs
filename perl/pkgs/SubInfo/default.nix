{
  buildPerlPackage,
  fetchurl,
  Importer,
}:

buildPerlPackage {
  pname = "Sub-Info";
  version = "0.002";
  src = fetchurl {
    url = "mirror://cpan/authors/id/E/EX/EXODIST/Sub-Info-0.002.tar.gz";
    hash = "sha256-6jBW1pa97/IamdNA1VcIh9OajMR7/yOt/ILfZ1jN0Oo=";
  };
  propagatedBuildInputs = [ Importer ];
  meta = {
    description = "Tool for inspecting subroutines";
  };
}
