{
  buildPerlPackage,
  fetchurl,
}:

buildPerlPackage {
  pname = "B-COW";
  version = "0.007";
  src = fetchurl {
    url = "mirror://cpan/authors/id/A/AT/ATOOMIC/B-COW-0.007.tar.gz";
    hash = "sha256-EpDa8ifosJiJoxzxguKRBvHPnxpOm/d1L53pLtEVi0Q=";
  };
  meta = {
    description = "B::COW additional B helpers to check COW status";
  };
}
