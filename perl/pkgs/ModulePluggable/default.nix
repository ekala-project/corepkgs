{
  AppFatPacker,
  buildPerlPackage,
  fetchurl,
}:

buildPerlPackage {
  pname = "Module-Pluggable";
  version = "5.2";
  src = fetchurl {
    url = "mirror://cpan/authors/id/S/SI/SIMONW/Module-Pluggable-5.2.tar.gz";
    hash = "sha256-s/KtReT9ELP7kNkS142LeVqylUgNtW3GToa5+nXFpt8=";
  };
  patches = [
    # !!! merge this patch into Perl itself (which contains Module::Pluggable as well)
    ./module-pluggable.patch
  ];
  buildInputs = [ AppFatPacker ];
  meta = {
    description = "Automatically give your module the ability to have plugins";
  };
}
