{
  buildPerlPackage,
  ClassDataInheritable,
  DevelStackTrace,
  fetchurl,
}:

buildPerlPackage {
  pname = "Exception-Class";
  version = "1.45";
  src = fetchurl {
    url = "mirror://cpan/authors/id/D/DR/DROLSKY/Exception-Class-1.45.tar.gz";
    hash = "sha256-VIKnfvAnyh+fOeH0jFWDVulUk2/I+73ubIEcUScBskk=";
  };
  propagatedBuildInputs = [
    ClassDataInheritable
    DevelStackTrace
  ];
  meta = {
    description = "Exception Object Class";
  };
}
