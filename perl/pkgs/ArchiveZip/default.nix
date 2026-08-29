{
  buildPerlPackage,
  fetchurl,
  TestMockModule,
}:

buildPerlPackage {
  pname = "Archive-Zip";
  version = "1.68";
  src = fetchurl {
    url = "mirror://cpan/authors/id/P/PH/PHRED/Archive-Zip-1.68.tar.gz";
    hash = "sha256-mE4YXXhbr2EpxudfjrREEXRawAv2Ei+xyOgio4YexlA=";
  };
  buildInputs = [ TestMockModule ];
  meta = {
    description = "Provide an interface to ZIP archive files";
    mainProgram = "crc32";
  };
}
