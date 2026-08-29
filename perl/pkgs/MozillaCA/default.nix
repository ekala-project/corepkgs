{
  buildPerlPackage,
  cacert,
  fetchurl,
  lib,
}:

buildPerlPackage {
  pname = "Mozilla-CA";
  version = "20230821";
  src = fetchurl {
    url = "mirror://cpan/authors/id/L/LW/LWP/Mozilla-CA-20230821.tar.gz";
    hash = "sha256-MuHQBFKZAEBFucTRbC2q5FOiFiCIc97qJED3EmCnzaE=";
  };

  postPatch = ''
    ln -s --force ${cacert}/etc/ssl/certs/ca-bundle.crt lib/Mozilla/CA/cacert.pem
  '';

  meta = {
    description = "Mozilla's CA cert bundle in PEM format";
    homepage = "https://github.com/gisle/mozilla-ca";
    license = with lib.licenses; [ mpl20 ];
  };
}
