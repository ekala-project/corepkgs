{
  buildPerlPackage,
  fetchurl,
  MROCompat,
  PackageStash,
  SubIdentify,
  TestFatal,
}:

buildPerlPackage {
  pname = "Devel-OverloadInfo";
  version = "0.007";
  src = fetchurl {
    url = "mirror://cpan/authors/id/I/IL/ILMARI/Devel-OverloadInfo-0.007.tar.gz";
    hash = "sha256-IaGEFjuQ+R8G/8f13guWg1ZUaum0AKnXXFc8lYwkYiI=";
  };
  propagatedBuildInputs = [
    MROCompat
    PackageStash
    SubIdentify
  ];
  buildInputs = [ TestFatal ];
  meta = {
    description = "Introspect overloaded operators";
  };
}
