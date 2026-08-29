{
  buildPerlPackage,
  fetchurl,
  ParamsUtil,
  SubInstall,
}:

buildPerlPackage {
  pname = "Data-OptList";
  version = "0.114";
  src = fetchurl {
    url = "mirror://cpan/authors/id/R/RJ/RJBS/Data-OptList-0.114.tar.gz";
    hash = "sha256-n9EJO5F6Ift5rhYH21PRE7TgrY/grndssHen5QBE/fM=";
  };
  propagatedBuildInputs = [
    ParamsUtil
    SubInstall
  ];
  meta = {
    description = "Parse and validate simple name/value option pairs";
    homepage = "https://github.com/rjbs/Data-OptList";
  };
}
