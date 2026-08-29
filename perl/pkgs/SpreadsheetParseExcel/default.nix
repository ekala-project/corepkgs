{
  buildPerlPackage,
  CryptRC4,
  DigestPerlMD5,
  fetchurl,
  IOStringy,
  OLEStorage_Lite,
}:

buildPerlPackage {
  pname = "Spreadsheet-ParseExcel";
  version = "0.66";
  src = fetchurl {
    url = "mirror://cpan/authors/id/J/JM/JMCNAMARA/Spreadsheet-ParseExcel-0.66.tar.gz";
    hash = "sha256-v9dqz7qYhgHcBRvac7S7JfaDmgBt2WC2p0AcJJJF9ls=";
  };
  propagatedBuildInputs = [
    CryptRC4
    DigestPerlMD5
    IOStringy
    OLEStorage_Lite
  ];
  meta = {
    description = "Read information from an Excel file";
    homepage = "https://github.com/runrig/spreadsheet-parseexcel";
  };
}
