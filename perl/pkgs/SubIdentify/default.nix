{
  buildPerlPackage,
  fetchurl,
}:

buildPerlPackage {
  pname = "Sub-Identify";
  version = "0.14";
  src = fetchurl {
    url = "mirror://cpan/authors/id/R/RG/RGARCIA/Sub-Identify-0.14.tar.gz";
    hash = "sha256-Bo0nIIZRTdHoQrakCxvtuv7mOQDlsIiQ72cAA53vrW8=";
  };
  meta = {
    description = "Retrieve names of code references";
  };
}
