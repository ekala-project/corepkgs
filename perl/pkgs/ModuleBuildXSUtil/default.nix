{
  buildPerlModule,
  CaptureTiny,
  CwdGuard,
  DevelCheckCompiler,
  fetchurl,
  FileCopyRecursiveReduced,
}:

buildPerlModule {
  pname = "Module-Build-XSUtil";
  version = "0.19";
  src = fetchurl {
    url = "mirror://cpan/authors/id/H/HI/HIDEAKIO/Module-Build-XSUtil-0.19.tar.gz";
    hash = "sha256-kGOzw0bt60IoB//kn/sjA4xPkA1Kd7hFzktT2XvylAA=";
  };
  buildInputs = [
    CaptureTiny
    CwdGuard
    FileCopyRecursiveReduced
  ];
  propagatedBuildInputs = [ DevelCheckCompiler ];
  meta = {
    description = "Module::Build class for building XS modules";
    homepage = "https://github.com/hideo55/Module-Build-XSUtil";
  };
}
