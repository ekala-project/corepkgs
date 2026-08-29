{
  buildPerlPackage,
  fetchurl,
}:

buildPerlPackage {
  pname = "Devel-Cycle";
  version = "1.12";
  src = fetchurl {
    url = "mirror://cpan/authors/id/L/LD/LDS/Devel-Cycle-1.12.tar.gz";
    hash = "sha256-/TNlxNiYsrK927eKRtUHoYzKhJCikBmVR9q38ec5C8I=";
  };
  meta = {
    description = "Find memory cycles in objects";
  };
}
