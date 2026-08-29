{
  buildPerlPackage,
  fetchurl,
  lib,
  perl,
  stdenv,
}:

let
  cross = stdenv.hostPlatform != stdenv.buildPlatform;
in
buildPerlPackage {
  pname = "TermReadKey";
  version = "2.38";
  src = fetchurl {
    url = "mirror://cpan/authors/id/J/JS/JSTOWE/TermReadKey-2.38.tar.gz";
    hash = "sha256-WmRYeNxXCsM2YVgfuwkP8k684X1D6lP9IuEFqFakcpA=";
  };

  # use native libraries from the host when running build commands
  postConfigure = lib.optionalString cross (
    let
      host_perl = perl.perlOnBuild;
      host_self = perl.perlOnBuild.pkgs.TermReadKey;
      perl_lib = "${host_perl}/lib/perl5/${host_perl.version}";
      self_lib = "${host_self}/lib/perl5/site_perl/${host_perl.version}";
    in
    ''
      sed -i -e 's|"-I$(INST_ARCHLIB)"|"-I${perl_lib}" "-I${self_lib}"|g' Makefile
    ''
  );

  # TermReadKey uses itself in the build process
  nativeBuildInputs = lib.optionals cross [
    perl.perlOnBuild.pkgs.TermReadKey
  ];
  meta = {
    description = "Perl module for simple terminal control";
  };
}
