{
  buildPerlPackage,
  CPANMetaCheck,
  fetchurl,
  PadWalker,
}:

buildPerlPackage {
  pname = "Test-Warnings";
  version = "0.032";
  src = fetchurl {
    url = "mirror://cpan/authors/id/E/ET/ETHER/Test-Warnings-0.032.tar.gz";
    hash = "sha256-Ryfa4kFunwfkHi3DqRQ7pq/8HsV2UhF8mdUAOOMT6dk=";
  };
  buildInputs = [
    CPANMetaCheck
    PadWalker
  ];
  meta = {
    description = "Test for warnings and the lack of them";
    homepage = "https://github.com/karenetheridge/Test-Warnings";
  };
}
