{
  buildPerlPackage,
  fetchurl,
}:

buildPerlPackage {
  pname = "Sub-Uplevel";
  version = "0.2800";
  src = fetchurl {
    url = "mirror://cpan/authors/id/D/DA/DAGOLDEN/Sub-Uplevel-0.2800.tar.gz";
    hash = "sha256-tPP2O4D2gKQhMy2IUd2+Wo5y/Kp01dHZjzyMxKPs4pM=";
  };
  meta = {
    description = "Apparently run a function in a higher stack frame";
    homepage = "https://github.com/Perl-Toolchain-Gang/Sub-Uplevel";
  };
}
