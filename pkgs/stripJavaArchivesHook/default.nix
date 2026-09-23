{ makeSetupHook, perlPackages }:

makeSetupHook {
  name = "strip-java-archives-hook";
  propagatedBuildInputs = [ perlPackages.strip-nondeterminism ];
} ./strip-java-archives.sh
