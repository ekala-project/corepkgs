{
  buildPerlPackage,
  fetchurl,
}:

buildPerlPackage {
  pname = "Digest-HMAC";
  version = "1.05";
  src = fetchurl {
    url = "mirror://cpan/authors/id/A/AR/ARODLAND/Digest-HMAC-1.05.tar.gz";
    hash = "sha256-IVy1nLphB0XPstSz+O91bVkOV+OteYapkuh8SWn83Ho=";
  };
  meta = {
    description = "Keyed-Hashing for Message Authentication";
  };
}
