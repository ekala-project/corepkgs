{
  buildPerlPackage,
  fetchurl,
}:

buildPerlPackage {
  pname = "YAML-LibYAML";
  version = "0.89";
  src = fetchurl {
    url = "mirror://cpan/authors/id/T/TI/TINITA/YAML-LibYAML-0.89.tar.gz";
    hash = "sha256-FVq4NnU0XFCt0DMRrPndkVlVcH+Qmiq9ixfXeShZsuw=";
  };
  meta = {
    description = "Perl YAML Serialization using XS and libyaml";
  };
}
