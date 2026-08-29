{
  buildPerlPackage,
  fetchurl,
  lib,
}:

buildPerlPackage {
  pname = "File-pushd";
  version = "1.016";
  src = fetchurl {
    url = "mirror://cpan/authors/id/D/DA/DAGOLDEN/File-pushd-1.016.tar.gz";
    hash = "sha256-1zp/CUQpg7CYJg3z33qDKl9mB3OjE8onP6i1ZmX5fNw=";
  };
  meta = {
    description = "Change directory temporarily for a limited scope";
    homepage = "https://github.com/dagolden/File-pushd";
    license = with lib.licenses; [ asl20 ];
  };
}
