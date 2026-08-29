{
  buildPerlPackage,
  fetchurl,
  IPCRun,
  lib,
}:

buildPerlPackage {
  pname = "Module-Signature";
  version = "0.87";
  src = fetchurl {
    url = "mirror://cpan/authors/id/A/AU/AUDREYT/Module-Signature-0.87.tar.gz";
    hash = "sha256-IU6AVcUP7DcalXQ1IP4mlAAE52FpBjsrROyQoNRdaYI=";
  };
  buildInputs = [ IPCRun ];
  meta = {
    description = "Module signature file manipulation";
    license = with lib.licenses; [ cc0 ];
    mainProgram = "cpansign";
  };
}
