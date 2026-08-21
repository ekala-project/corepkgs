{
  lib,
  fetchFromGitLab,
  perlPackages,
}:

perlPackages.buildPerlPackage {
  pname = "strip-nondeterminism";
  version = "1.14.0";

  src = fetchFromGitLab {
    owner = "reproducible-builds";
    repo = "strip-nondeterminism";
    tag = "1.14.0";
    hash = "sha256-EfOFl51GgFIMfhHpkz3S4bpk5nnqJ0cLBpbPur6cpSI=";
  };

  propagatedBuildInputs = with perlPackages; [
    ArchiveZip
  ];

  postPatch = ''
    substituteInPlace Makefile.PL \
      --replace-fail "my \$dist_version = `dpkg-parsechangelog" \
                     "my \$dist_version = '1.14.0'; #"
  '';

  installTargets = [ "install" ];

  meta = {
    description = "Tool for stripping bits of non-deterministic information from files";
    homepage = "https://reproducible-builds.org/";
    license = lib.licenses.gpl3Plus;
    mainProgram = "strip-nondeterminism";
  };
}
