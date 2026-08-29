{
  buildPerlPackage,
  fetchurl,
}:

buildPerlPackage {
  pname = "libnet";
  version = "3.15";
  src = fetchurl {
    url = "mirror://cpan/authors/id/S/SH/SHAY/libnet-3.15.tar.gz";
    hash = "sha256-px9NtYDhp2fWk2+qW6848fpheCQ0LaB4tWEoPob49KI=";
  };
  meta = {
    description = "Collection of network protocol modules";
  };
}
