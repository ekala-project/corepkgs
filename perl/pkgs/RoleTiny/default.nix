{
  buildPerlPackage,
  fetchurl,
}:

buildPerlPackage {
  pname = "Role-Tiny";
  version = "2.002004";
  src = fetchurl {
    url = "mirror://cpan/authors/id/H/HA/HAARG/Role-Tiny-2.002004.tar.gz";
    hash = "sha256-173unhOKT4OqUtCpgWJWRL2of/FmQt+oRdy0TZokK0U=";
  };
  meta = {
    description = "Roles: a nouvelle cuisine portion size slice of Moose";
  };
}
