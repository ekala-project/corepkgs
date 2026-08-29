{
  buildPerlPackage,
  fetchurl,
  HTTPDate,
  lib,
  TestDeep,
  TestRequires,
  URI,
}:

buildPerlPackage {
  pname = "HTTP-CookieJar";
  version = "0.014";
  src = fetchurl {
    url = "mirror://cpan/authors/id/D/DA/DAGOLDEN/HTTP-CookieJar-0.014.tar.gz";
    hash = "sha256-cJTqXJH1NtJjuF6Dq06alj4RxECM4I7K5VP6nAzEfnM=";
  };
  propagatedBuildInputs = [ HTTPDate ];
  buildInputs = [
    TestDeep
    TestRequires
    URI
  ];
  # Broken on Hydra since 2021-06-17: https://hydra.nixos.org/build/146507373
  doCheck = false;
  meta = {
    description = "Minimalist HTTP user agent cookie jar";
    homepage = "https://github.com/dagolden/HTTP-CookieJar";
    license = with lib.licenses; [ asl20 ];
  };
}
